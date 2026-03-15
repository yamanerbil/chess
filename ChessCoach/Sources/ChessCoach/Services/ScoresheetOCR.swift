import Foundation
import Vision
#if canImport(UIKit)
import UIKit
#endif

/// Service that performs OCR on scoresheet images and parses chess notation
enum ScoresheetOCR {

    /// Result of scanning a scoresheet image
    struct ScanResult {
        let rawText: String
        let moves: [ScannedMove]
        let savedImagePath: String?
    }

    /// Recognize text from a CGImage using Vision framework
    static func recognizeText(from cgImage: CGImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }

                // Collect all recognized text lines sorted top-to-bottom
                let lines = observations
                    .sorted { $0.boundingBox.origin.y > $1.boundingBox.origin.y }
                    .compactMap { $0.topCandidates(1).first?.string }

                let fullText = lines.joined(separator: "\n")
                continuation.resume(returning: fullText)
            }

            // Configure for handwriting
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            request.revision = VNRecognizeTextRequestRevision3

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Parse raw OCR text into ScannedMove array
    static func parseMoves(from ocrText: String) -> [ScannedMove] {
        let cleanedSANs = parseOCRToSANs(ocrText)

        var moves: [ScannedMove] = []
        for (index, san) in cleanedSANs.enumerated() {
            let color: PieceColor = (index % 2 == 0) ? .white : .black
            let moveNumber = (index / 2) + 1
            moves.append(ScannedMove(
                san: san,
                moveNumber: moveNumber,
                color: color,
                status: .valid // will be re-validated by MoveCorrectionViewModel
            ))
        }
        return moves
    }

    /// Full pipeline: OCR → parse → validate
    static func processImage(_ cgImage: CGImage) async throws -> ScanResult {
        let rawText = try await recognizeText(from: cgImage)
        let moves = parseMoves(from: rawText)
        let savedPath = saveImage(cgImage)
        return ScanResult(rawText: rawText, moves: moves, savedImagePath: savedPath)
    }

    // MARK: - Claude Vision OCR

    /// Use Claude's vision capability to read chess moves from a scoresheet image.
    /// Much more accurate than Apple Vision for handwritten chess notation.
    static func processImageWithClaude(_ cgImage: CGImage, client: ClaudeAPIClient) async throws -> ScanResult {
        let imageData = jpegData(from: cgImage)
        guard let data = imageData else {
            throw ClaudeOCRError.imageConversionFailed
        }

        let systemPrompt = """
        You are a chess scoresheet OCR system. Your job is to extract chess moves \
        from photos of handwritten tournament scoresheets.

        RULES:
        1. Output ONLY the moves in standard algebraic notation (SAN), one per line
        2. Format: "1. e4 e5" (move number, dot, white move, black move)
        3. Use proper piece letters: K, Q, R, B, N (uppercase)
        4. Use proper file letters: a-h (lowercase) and rank numbers: 1-8
        5. Use "x" for captures, "+" for check, "#" for checkmate
        6. Use "O-O" for kingside castling, "O-O-O" for queenside castling
        7. If a move is completely illegible, write "???" as a placeholder
        8. Do NOT include annotations, comments, or evaluations
        9. If the scoresheet has a result (1-0, 0-1, 1/2-1/2), include it on the last line
        10. Read carefully — handwritten scoresheets are often messy. Use your knowledge \
        of chess to infer likely moves when handwriting is ambiguous.
        """

        let userMessage = """
        Extract all chess moves from this handwritten scoresheet image. \
        Output only the moves in standard algebraic notation, numbered sequentially.
        """

        let response = try await client.sendMessageWithImage(
            system: systemPrompt,
            userMessage: userMessage,
            imageData: data,
            mediaType: "image/jpeg",
            maxTokens: 2048
        )

        let moves = parseClaudeResponse(response)
        let savedPath = saveImage(cgImage)
        return ScanResult(rawText: response, moves: moves, savedImagePath: savedPath)
    }

    /// Parse Claude's response into ScannedMove array
    private static func parseClaudeResponse(_ text: String) -> [ScannedMove] {
        // Claude returns numbered moves like "1. e4 e5\n2. Nf3 Nc6\n..."
        let sans = parseSANMoves(from: text)

        var moves: [ScannedMove] = []
        for (index, san) in sans.enumerated() {
            // Skip result strings
            if san == "1-0" || san == "0-1" || san == "1/2-1/2" { continue }
            // Skip placeholder for illegible moves
            let status: ScannedMove.MoveStatus = (san == "???") ? .illegal : .valid
            let color: PieceColor = (index % 2 == 0) ? .white : .black
            let moveNumber = (index / 2) + 1
            moves.append(ScannedMove(
                san: san,
                moveNumber: moveNumber,
                color: color,
                status: status
            ))
        }
        return moves
    }

    /// Convert CGImage to JPEG data for API upload
    private static func jpegData(from cgImage: CGImage, quality: CGFloat = 0.85) -> Data? {
        #if canImport(UIKit)
        let uiImage = UIImage(cgImage: cgImage)
        return uiImage.jpegData(compressionQuality: quality)
        #else
        return nil
        #endif
    }

    enum ClaudeOCRError: LocalizedError {
        case imageConversionFailed
        case apiNotConfigured

        var errorDescription: String? {
            switch self {
            case .imageConversionFailed:
                return "Failed to convert scoresheet image for upload."
            case .apiNotConfigured:
                return "Claude API key not configured. Go to Settings to add your API key, or use on-device scanning."
            }
        }
    }

    // MARK: - OCR Text → SAN Parsing

    /// Parse OCR text that may contain scoresheet formatting into SAN moves.
    /// Handles common OCR misreads and scoresheet layouts.
    static func parseOCRToSANs(_ text: String) -> [String] {
        // Normalize the text
        var cleaned = text

        // Common OCR substitutions for chess notation
        let ocrFixes: [(String, String)] = [
            ("0-0-0", "O-O-O"),  // castling with zeros
            ("0-0", "O-O"),
            ("o-o-o", "O-O-O"),
            ("o-o", "O-O"),
            ("l", "1"),          // lowercase L → 1 (in move numbers)
            ("I", "1"),          // capital I → 1 (in move numbers context)
        ]

        for (from, to) in ocrFixes {
            cleaned = cleaned.replacingOccurrences(of: from, with: to)
        }

        // Split into tokens and use the existing parser
        let sans = parseSANMoves(from: cleaned)

        // Apply chess-specific OCR corrections to each SAN
        return sans.map { correctOCRMove($0) }
    }

    /// Fix common OCR misreads in individual chess moves
    private static func correctOCRMove(_ san: String) -> String {
        var move = san

        // Fix common piece letter confusions
        // "8" often misread as "B" (bishop) — but only at start
        // "K" sometimes misread as "k"
        if let first = move.first, first.isLowercase, "kqrbn".contains(first) {
            // Capitalize piece letters (but not file letters a-h)
            if !"abcdefgh".contains(first) {
                move = first.uppercased() + String(move.dropFirst())
            }
        }

        // Fix "x" variants: "X", "×" → "x"
        move = move.replacingOccurrences(of: "×", with: "x")
        move = move.replacingOccurrences(of: "X", with: "x")

        // Fix check symbols
        move = move.replacingOccurrences(of: "†", with: "+")

        // Remove stray characters that aren't part of chess notation
        let validChars = CharacterSet(charactersIn: "KQRBNabcdefgh12345678xO-=+#")
        move = String(move.unicodeScalars.filter { validChars.contains($0) })

        return move
    }

    // MARK: - Image Saving

    /// Save the scoresheet image as PNG to the app's documents directory
    @discardableResult
    static func saveImage(_ cgImage: CGImage) -> String? {
        #if canImport(UIKit)
        let uiImage = UIImage(cgImage: cgImage)
        guard let data = uiImage.pngData() else { return nil }

        let filename = "scoresheet_\(Int(Date().timeIntervalSince1970)).png"
        guard let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let fileURL = docsURL.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL)
            return fileURL.path
        } catch {
            return nil
        }
        #else
        return nil
        #endif
    }
}
