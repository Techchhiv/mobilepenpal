<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use PhpOffice\PhpWord\PhpWord;
use PhpOffice\PhpWord\IOFactory;
use PhpOffice\PhpWord\Shared\Html;
use PhpOffice\PhpWord\Style\Alignment;
use PhpOffice\PhpWord\SimpleType\Jc;
use thiagoalessio\TesseractOCR\TesseractOCR;

class ImageToWordController extends Controller
{
    public function convert(Request $request)
    {
        $request->validate([
            'image' => 'required|image|max:5120',  // Validate uploaded image
        ]);

        // Store the uploaded image and get its path
        $path = $request->file('image')->store('images');
        $imagePath = storage_path('app/' . $path);

        // Set TESSDATA_PREFIX path
        $tessdataDir = '/usr/local/share/tessdata'; // Update based on your setup
        putenv("TESSDATA_PREFIX=$tessdataDir");

        // Extract OCR text with layout preserved (basic OCR)
        try {
            $text = (new TesseractOCR($imagePath))
                ->lang('khm+eng')  // Use Khmer and English language for OCR
                ->preserve_interword_spaces()
                ->psm(1)  // Page segmentation mode for layout preservation
                ->run();
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'OCR conversion failed: ' . $e->getMessage(),
            ], 500);
        }

        // Initialize PHPWord to create Word document
        $phpWord = new PhpWord();
        $section = $phpWord->addSection();

        // Add original image to the Word document
        $section->addText("📸 Original Document:", ['bold' => true, 'size' => 14]);
        $section->addImage($imagePath, [
            'width' => 500,
            'alignment' => Jc::CENTER,
        ]);

        $section->addTextBreak(2); // Add space between image and extracted text

        // Add extracted OCR text to Word document
        $section->addText("📝 Extracted Text:", ['bold' => true, 'size' => 14]);

        // Split the OCR text by new lines and add each line to the Word document
        foreach (explode("\n", $text) as $line) {
            // You can adjust the position, font size, and alignment as per your needs
            $section->addText($line, ['size' => 12]);
        }

        // Define the file name and save path
        $filename = 'converted_with_image_and_text.docx';
        $filePath = storage_path("app/public/{$filename}");

        // Save the Word document
        $writer = IOFactory::createWriter($phpWord, 'Word2007');
        $writer->save($filePath);

        return response()->json([
            'success' => true,
            'message' => 'File with image and formatted text created.',
            'file_url' => asset('storage/' . $filename),
        ]);
    }
}
