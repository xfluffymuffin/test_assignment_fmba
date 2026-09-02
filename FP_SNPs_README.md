# FP_SNPs_README (EN)
 
## Preprocessing the FP_SNPs.txt input file
 
The following command was used:
 
```
awk -F'\t' 'BEGIN{OFS="\t"; print "#CHROM","POS","ID","allele1","allele2"}
NR>1 && NF && $2!=23 {print "chr"$2, $4, "rs"$1, $5, $6}' FP_SNPs.txt > FP_SNPs_10k_GB38_twoAllelsFormat.tsv
```
 
Explanation of each component:
 
- `-F'\t'` - specifies that fields in the source file are separated by tabs;
- `BEGIN{...}` - a block executed once, before any input lines are processed; it is used here to print the header a single time rather than for every line;
- `OFS="\t"` - defined inside BEGIN, this sets the separator for the *output* file, as distinct from `-F'\t'`, which governs the *input* separator;
- `NR>1 && NF` - restricts processing to non-empty lines (`NF`) starting from line 2 (`NR>1`), so the header is not treated as data and the empty line 11002 at the end of the file is excluded;
- `$2!=23` - excludes any line whose second column equals 23 (the X chromosome);
- `{print "chr"$2, $4, "rs"$1, $5, $6}` - reorders the columns from the source file into the new sequence (2, 4, 1, 5, 6) and adds the required prefixes;
- `FP_SNPs.txt > FP_SNPs_10k_GB38_twoAllelsFormat.tsv` - directs the command's output into a new file under the specified name.

For comparison:
 
a)
 
```
head -n 3 FP_SNPs.txt
rs#     chromosome      GB37_position   GB38_position   allele1 allele2
2887286 1       1156131 1220751 C       T
6685064 1       1211292 1275912 T       C
 
head -n 3 FP_SNPs_10k_GB38_twoAllelsFormat.tsv
#CHROM  POS     ID      allele1 allele2
chr1    1220751 rs2887286       C       T
chr1    1275912 rs6685064       T       C
```
 
b)
 
```
tail -n 3 FP_SNPs.txt
4898348 23      153886394       154658120       G       A
2728729 23      154009347       154781072       A       G
11887   23      154467457       155239176       G       A
 
tail -n 3 FP_SNPs_10k_GB38_twoAllelsFormat.tsv
chr22   50118978        rs138229        G       A
chr22   50226183        rs4838865       A       G
chr22   50577409        rs3213445       C       T
```
 
c)
 
```
wc -l FP_SNPs.txt
11001 FP_SNPs.txt
 
wc -l FP_SNPs_10k_GB38_twoAllelsFormat.tsv
10001 FP_SNPs_10k_GB38_twoAllelsFormat.tsv
```
 
The original file contained 10000 SNPs on the autosomes (chromosomes 1-22) and 1000 SNPs on the X chromosome (chromosome 23). After preprocessing, the file contains 10000 data lines (plus the header line), as the X-chromosome variants were removed per the task requirements, and the GB37 coordinate column was not carried over into the new file.
 
## About the restore_ref_al.py script
 
This script converts a file in the `#CHROM\tPOS\tID\tallele1\tallele2` format into the `#CHROM\tPOS\tID\tREF\tALT` format. It determines the reference and alternate alleles by comparing allele1/allele2 against the actual nucleotide at the corresponding position in the reference genome (via pysam.FastaFile).
 
### Command-line arguments
 
- `--input`, `-i` (required) - path to the input file (allele1/allele2 format);
- `--output`, `-o` (required) - path to the output file (REF/ALT format);
- `--reference`, `-r` (required) - path to the directory holding the reference genome files (`chr*.fa[.fai]`);
- `--log`, `-l` (required) - path to the log file.
A description is also available on request:
 
```
restore_ref_al.py --help
```
 
### How it works
 
1. The script verifies that the input file exists and that its header is correctly formatted.
2. The file is read line by line, independent of the line-ending format used.
3. For each line, #CHROM and POS are used with pysam.FastaFile.fetch() to retrieve the reference nucleotide at that position (adjusted for 1-based/0-based coordinates). FastaFile objects are cached per chromosome so that the same file is not opened repeatedly.
4. Whichever of allele1/allele2 matches the reference nucleotide is recorded as REF, and the other as ALT.
5. Lines where neither allele matches the reference (or where the line is malformed, or no reference is available for the given chromosome/position) are skipped and logged with the corresponding reason.
6. The log includes timestamps throughout, a warning entry for each skipped line, and a final summary (processed / matched / ambiguous / malformed).
## Getting this into the Docker image
 
Installation of pysam and copying of the script into the image have both been added to the repository's main Dockerfile (the layer containing `pip install pysam` and `COPY restore_ref_al.py`).
 
## Build and run
 
Build the image:
 
```
docker build -t test_assignment_fmba:test .
```
 
Run the script inside a container (the reference genome is mounted from the host, as is the working directory containing the input file):
 
```
docker run --rm \
    -v "/mnt/data/ref/GRCh38.d1.vd1_mainChr/sepChrs:/ref/GRCh38.d1.vd1_mainChr/sepChrs" \
    -v "/path/to/workdir:/workdir" \
    -w /workdir \
    test_assignment_fmba:test \
    restore_ref_al.py -i FP_SNPs_10k_GB38_twoAllelsFormat.tsv \
                       -o FP_SNPs_10k_GB38_REFALT.tsv \
                       -r /ref/GRCh38.d1.vd1_mainChr/sepChrs \
                       -l FP_SNPs_restore.log
```
 
## Results
 
A total of 10000 variants were processed.
 
- Successfully matched (REF/ALT assigned): 9991
- Ambiguous (neither allele matched the reference): 9
- Malformed lines: 0
The 9 ambiguous variants (full warning list is in the log file): rs2274617, rs4342964, rs11204215, rs12414155, rs2790937, rs10994675, rs527464, rs7174982, rs4778334.
 
A likely explanation is that the alleles for these SNPs in the source data are given relative to the minus strand of the DNA, whereas pysam.FastaFile.fetch() always returns the plus-strand nucleotide of the reference genome. For example, for rs2274617 the reference base is G and the alleles are T/C; complementing the alleles (T→A, C→G) yields a match between the reference G and the complement of allele C. This pattern holds for the remaining 8 cases as well. The current version of the script does not perform automatic strand-complement checking, such variants are simply flagged as ambiguous and excluded from the output file.
 
---

# FP_SNPs_README (RU)

## Предподготовка входного файла FP_SNPs.txt

Была использована команда:

```
awk -F'\t' 'BEGIN{OFS="\t"; print "#CHROM","POS","ID","allele1","allele2"}
NR>1 && NF && $2!=23 {print "chr"$2, $4, "rs"$1, $5, $6}' FP_SNPs.txt > FP_SNPs_10k_GB38_twoAllelsFormat.tsv
```

где:

- `-F'\t'` - указывает, что в исходном файле разделитель - знак табуляции;
- `BEGIN{...}` - блок, который выполняется один раз до обработки строк файла (используется, чтобы напечатать заголовок один раз, а не для каждой строки);
- `OFS="\t"` - отдельно устанавливает внутри BEGIN разделитель именно для вывода (Output Field Separator), в отличие от `-F'\t'`, который отвечает за разделитель входного файла;
- `NR>1 && NF` - указывает на работу в исходном файле с непустыми строками (NF), начиная со 2-й (NR>1), чтобы не обработать заголовок как данные и исключить пустую строку 11002;
- `$2!=23` - запрещает обработку строки исходного файла, если у нее значение во втором столбце равно 23;
- `{print "chr"$2, $4, "rs"$1, $5, $6}` - переставляет столбцы из старого файла в новый в последовательности 2, 4, 1, 5, 6 с добавлением требуемых префиксов;
- `FP_SNPs.txt > FP_SNPs_10k_GB38_twoAllelsFormat.tsv` - направляет вывод команды в новый файл с заданным именем.

Дополнительно для сравнения:

а)

```
head -n 3 FP_SNPs.txt
rs#     chromosome      GB37_position   GB38_position   allele1 allele2
2887286 1       1156131 1220751 C       T
6685064 1       1211292 1275912 T       C

head -n 3 FP_SNPs_10k_GB38_twoAllelsFormat.tsv
#CHROM  POS     ID      allele1 allele2
chr1    1220751 rs2887286       C       T
chr1    1275912 rs6685064       T       C
```

б)

```
tail -n 3 FP_SNPs.txt
4898348 23      153886394       154658120       G       A
2728729 23      154009347       154781072       A       G
11887   23      154467457       155239176       G       A

tail -n 3 FP_SNPs_10k_GB38_twoAllelsFormat.tsv
chr22   50118978        rs138229        G       A
chr22   50226183        rs4838865       A       G
chr22   50577409        rs3213445       C       T
```

в)

```
wc -l FP_SNPs.txt
11001 FP_SNPs.txt

wc -l FP_SNPs_10k_GB38_twoAllelsFormat.tsv
10001 FP_SNPs_10k_GB38_twoAllelsFormat.tsv
```

Всего в исходном файле было 10000 SNP на аутосомах (хромосомы 1-22) и 1000 SNP на X-хромосоме (хромосома 23). После предобработки в файле осталось 10000 строк с данными (плюс строка заголовка), так как варианты X-хромосомы были удалены согласно заданию, а колонка с координатами GB37 не переносилась в новый файл.

## Описание скрипта restore_ref_al.py

Скрипт преобразует файл формата `#CHROM\tPOS\tID\tallele1\tallele2` в формат `#CHROM\tPOS\tID\tREF\tALT`, определяя референсный и альтернативный аллели путем сравнения allele1/allele2 с реальным нуклеотидом в указанной позиции референсного генома (через pysam.FastaFile).

### Аргументы командной строки

- `--input`, `-i` (обязательный) - путь к входному файлу (формат allele1/allele2);
- `--output`, `-o` (обязательный) - путь к выходному файлу (формат REF/ALT);
- `--reference`, `-r` (обязательный) - путь к директории с файлами референсного генома (`chr*.fa[.fai]`);
- `--log`, `-l` (обязательный) - путь к лог-файлу.

Описание также доступно по запросу:

```
restore_ref_al.py --help
```

### Логика работы

1. Проверяется существование входного файла и корректность его заголовка.
2. Файл читается построчно (независимо от формата конца строк).
3. Для каждой строки по #CHROM и POS через pysam.FastaFile.fetch() извлекается референсный нуклеотид в этой позиции (с поправкой на 1-based/0-based координаты). Объекты FastaFile кэшируются по хромосоме, чтобы не открывать один и тот же файл повторно.
4. Тот из allele1/allele2, что совпал с референсным нуклеотидом, записывается как REF, второй - как ALT.
5. Строки, где ни один из аллелей не совпал с референсом (или где формат строки нарушен, либо референс для хромосомы/позиции недоступен), пропускаются и логируются с указанием причины.
6. В лог пишутся временные метки, предупреждения по каждой пропущенной строке, и итоговая статистика (обработано/успешно сопоставлено/неоднозначные/некорректные).

## Установка в Docker-образ

Установка pysam и копирование скрипта добавлены в основной Dockerfile репозитория (слой с pip install pysam и COPY restore_ref_al.py).

## Сборка и запуск

Сборка образа:

```
docker build -t test_assignment_fmba:test .
```

Запуск скрипта в контейнере (референсный геном пробрасывается с хоста, рабочая директория с входным файлом - тоже):

```
docker run --rm \
    -v "/mnt/data/ref/GRCh38.d1.vd1_mainChr/sepChrs:/ref/GRCh38.d1.vd1_mainChr/sepChrs" \
    -v "/path/to/workdir:/workdir" \
    -w /workdir \
    test_assignment_fmba:test \
    restore_ref_al.py -i FP_SNPs_10k_GB38_twoAllelsFormat.tsv \
                       -o FP_SNPs_10k_GB38_REFALT.tsv \
                       -r /ref/GRCh38.d1.vd1_mainChr/sepChrs \
                       -l FP_SNPs_restore.log
```

## Результаты

Всего обработано 10000 вариантов.

- Успешно сопоставлено (REF/ALT определены): 9991
- Неоднозначные (ни один аллель не совпал с референсом): 9
- Некорректные строки: 0

9 неоднозначных вариантов (полный список предупреждений - в лог-файле): rs2274617, rs4342964, rs11204215, rs12414155, rs2790937, rs10994675, rs527464, rs7174982, rs4778334.

Вероятная причина: аллели для этих SNP в исходных данных, по-видимому, указаны относительно минус-цепи ДНК, тогда как pysam.FastaFile.fetch() всегда возвращает нуклеотид плюс-цепи референсного генома. Например, для rs2274617 референс - G, аллели - T/C; при переводе аллелей в комплементарные основания (T→A, C→G) референс G совпадает с комплементом аллеля C. Это согласуется и с остальными 8 случаями. Скрипт в текущей версии не выполняет автоматическую проверку комплементарной цепи - такие варианты помечаются как неоднозначные и не попадают в выходной файл.
