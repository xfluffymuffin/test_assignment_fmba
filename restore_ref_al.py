import argparse
import logging
import os
import sys
import pysam


def main():
    parser = argparse.ArgumentParser(
        description="Convert allele1/allele2 SNP format to REF/ALT format using a reference genome."
    )
    parser.add_argument("--input", "-i", help="Path to input file", required=True)
    parser.add_argument("--output", "-o", help="Path to output file", required=True)
    parser.add_argument("--reference", "-r", help="Path to reference file", required=True)
    parser.add_argument("--log", "-l", help="Path to log file", required=True)
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO,
                        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
                        filename=args.log
                        )
    check_input(args.input)
    process_file(args.input, args.output, args.reference)

# Проверяет корректность входного файла (FP_SNPs_10k_GB38_twoAllelsFormat.tsv)
def check_input(input_file):
    line1_error = "First line has incorrect format"
    no_input_file = "Input file does not exist"

    if os.path.exists(input_file):
        with open(input_file, 'r') as f:
            if f.readline().rstrip() != "#CHROM\tPOS\tID\tallele1\tallele2":
                logging.error(line1_error)
                sys.exit(line1_error)
    else:
        logging.error(no_input_file)
        sys.exit(no_input_file)


# Возвращает pysam.FastFile для заданной хромосомы с исп. кэша (файл не открывается повторно)
def get_fasta(chrom, ref_dir, cache):
    if chrom not in cache:
        fasta_path = os.path.join(ref_dir, f"{chrom}.fa")
        if not os.path.exists(fasta_path):
            ref_err = f"Reference file not found for {chrom}: {fasta_path}"
            logging.error(ref_err)
            sys.exit(ref_err)
        cache[chrom] = pysam.FastaFile(fasta_path)
    return cache[chrom]


# pos - 1-based, pysam.fetch - 0-based half-open => запрашивается интервал [pos-1, pos)
def get_ref_base(chrom, pos, ref_dir, cache):
    fasta = get_fasta(chrom, ref_dir, cache)
    base = fasta.fetch(chrom, pos - 1, pos)
    return base.upper()


def process_file(input_file, output_file, ref_dir):
    cache = {}
    total = 0
    matched = 0
    unmatched = 0
    malformed = 0

    try:
        with open(input_file, 'r') as fin, open(output_file, 'w') as fout:
            header = fin.readline()
            fout.write("#CHROM\tPOS\tID\tREF\tALT\n")

            for line_num, line in enumerate(fin, start=2):  # start=2, т.к. строка 1 - заголовок
                line = line.rstrip()
                if not line:
                    continue
                total += 1

                try:
                    chrom, pos, snp_id, allele1, allele2 = line.split('\t')
                    pos = int(pos)
                except ValueError:
                    malformed += 1
                    logging.error(f"Line {line_num}: malformed line, skipped: '{line}'")
                    continue

                try:
                    ref_base = get_ref_base(chrom, pos, ref_dir, cache)
                except Exception as e:
                    malformed += 1
                    logging.error(f"Line {line_num}: failed to fetch reference base for {chrom}:{pos} — {e}")
                    continue

                if allele1 == ref_base and allele2 != ref_base:
                    ref, alt = allele1, allele2
                elif allele2 == ref_base and allele1 != ref_base:
                    ref, alt = allele2, allele1
                else:
                    unmatched += 1
                    logging.warning(
                        f"Line {line_num}: {snp_id} ({chrom}:{pos}): alleles {allele1}/{allele2} "
                        f"do not uniquely match reference base {ref_base} — skipped"
                    )
                    continue

                matched += 1
                fout.write(f"{chrom}\t{pos}\t{snp_id}\t{ref}\t{alt}\n")
    finally:
        for fasta in cache.values():
            fasta.close()

    logging.info(f"Total variants processed: {total}")
    logging.info(f"Matched (REF/ALT assigned): {matched}")
    logging.info(f"Unmatched (ambiguous alleles): {unmatched}")
    logging.info(f"Malformed lines (skipped): {malformed}")

if __name__=='__main__':
    main()
