<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;

class GenerateLstmf extends Command
{
    protected $signature = 'train:generate-lstmf';
    protected $description = 'Generate .lstmf files for OCR training';


    public function handle()
    {
        $trainingPath = storage_path('app/khmer_training');
        $files = glob("$trainingPath/*.png");

        foreach ($files as $image) {
            $basename = pathinfo($image, PATHINFO_FILENAME);
            $textFile = "$trainingPath/$basename.gt.txt";

            if (!file_exists($textFile)) {
                $this->error("Missing text file for $image");
                continue;
            }

            $command = "tesseract $image $trainingPath/$basename --psm 6 lstm.train";
            $this->info("Running: $command");
            shell_exec($command);
        }

        shell_exec("ls $trainingPath/*.lstmf > $trainingPath/list_of_lstmf.txt");

        $this->info('✅ LSTM Training Data Generated!');

    }
}
