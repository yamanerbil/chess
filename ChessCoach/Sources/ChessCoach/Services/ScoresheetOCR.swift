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
