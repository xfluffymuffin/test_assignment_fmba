# test_assignment_fmba

This repository contains a Dockerfile with a set of bioinformatics tools for genomic analysis. Base image: Ubuntu 22.04

## Specialized programs

- **samtools** 1.24 (2026-07-09) — a set of utilities for manipulating alignments in the SAM (Sequence Alignment/Map), BAM, and CRAM formats.
- **htslib** 1.24 (2026-07-09) — a unified C library for accessing common file formats (SAM, CRAM, VCF) used for high-throughput sequencing data; the core library on which samtools and bcftools are built.
- **libdeflate** 1.26 (2026-08-22) — a heavily optimized library for DEFLATE/zlib/gzip compression and decompression.
- **bcftools** 1.24 (2026-07-09) — a set of utilities for manipulating variant calls in the VCF (Variant Call Format) format and its binary counterpart BCF.
- **vcftools** 0.1.17 (2025-05-15) — a program package for working with VCF files.

## Environment variables

Each main specialized program has an environment variable holding the full path to its executable:

- $SAMTOOLS — path to the samtools binary
- $BCFTOOLS — path to the bcftools binary
- $VCFTOOLS — path to the vcftools binary
- $BGZIP — path to the bgzip binary (part of htslib)
- $TABIX — path to the tabix binary (part of htslib)

In addition, each auxiliary binary (libdeflate-gzip/libdeflate-gunzip, annot-tsv, ref-cache, htsfile) has its own environment variable following the same principle (see the Dockerfile for the full list).

The variables $SOFT (/soft — the root directory for all specialized programs) and $BCFTOOLS_PLUGINS (bcftools plugins directory) are also set.

## Building the Docker image

docker build -t test_assignment_fmba:test .

## Running the Docker image in interactive mode

docker run -it test_assignment_fmba:test bash

---

Содержит Dockerfile с набором биоинформатических инструментов для геномного анализа. Базовый образ: Ubuntu 22.04

## Специализированные программы

- **samtools** 1.24 (2026-07-09) — набор утилит для работы с выравниваниями в форматах SAM (Sequence Alignment/Map), BAM и CRAM.
- **htslib** 1.24 (2026-07-09) — унифицированная библиотека на C для работы с распространенными форматами файлов (SAM, CRAM, VCF), используемыми при высокопроизводительном секвенировании; является ядром, на котором построены samtools и bcftools.
- **libdeflate** 1.26 (2026-08-22) — высокооптимизированная библиотека для сжатия и распаковки данных в форматах DEFLATE/zlib/gzip.
- **bcftools** 1.24 (2026-07-09) — набор утилит для работы с генетическими вариантами в формате VCF (Variant Call Format) и его бинарным аналогом BCF.
- **vcftools** 0.1.17 (2025-05-15) — пакет программ для работы с файлами формата VCF.

## Переменные окружения

Для каждой основной специализированной программы задана переменная с полным путем до исполняемого файла:

- $SAMTOOLS — путь к бинарнику samtools
- $BCFTOOLS — путь к бинарнику bcftools
- $VCFTOOLS — путь к бинарнику vcftools
- $BGZIP — путь к бинарнику bgzip (входит в состав htslib)
- $TABIX — путь к бинарнику tabix (входит в состав htslib)

Также для каждого вспомогательного бинарника (libdeflate-gzip/libdeflate-gunzip, annot-tsv, ref-cache, htsfile) заведена отдельная переменная по аналогичному принципу (полный список см. в Dockerfile).

Заданы переменные $SOFT (/soft — корневая директория для всех специализированных программ) и $BCFTOOLS_PLUGINS (директория с плагинами bcftools).

## Сборка Docker-образа

docker build -t test_assignment_fmba:test .

## Запуск Docker-образа в интерактивном режиме

docker run -it test_assignment_fmba:test bash
