#!/bin/bash

# Solicita o n�mero de threads ao usu�rio
read -p "Enter the number of threads: " num_threads

# Solicita o caminho do arquivo de sequ�ncia
read -p "Enter the sequence file path (e.g., home/path/sequence.fa): " sequence_file

# Solicita o diret�rio contendo os metagenomas
read -p "Enter the directory  (e.g., home/path/metagenomes): " input_dir

# Gera o banco de dados BLAST a partir da sequ�ncia fornecida pelo usu�rio
makeblastdb -in "$sequence_file" -dbtype prot -out sequence

# Diret�rios de sa�da
output_dir="Seq"
predicted_dir="Output"

# Crie os diret�rios de sa�da se n�o existirem
mkdir -p $output_dir
mkdir -p $predicted_dir

# Define o n�mero m�ximo de processos paralelos (ajuste conforme o desempenho do seu sistema)
max_procs=4
current_procs=0

# Fun��o para processar cada arquivo
process_file() {
  local file_path=$1
  local file=$(basename "$file_path" .fa)

  # Execute o comando blastx para cada arquivo com o n�mero de threads fornecido pelo usu�rio
  blastx -query ${file_path} -db sequence -outfmt "6 qseqid" -evalue 1e-5 -out ${output_dir}/${file}.fa -num_threads $num_threads

  # Substitua o in�cio de cada linha por '>'
  sed -i 's/^/>/' ${output_dir}/${file}.fa
  
  # Execute o comando awk para filtrar as sequ�ncias
  awk 'NR==FNR {if($0 ~ /^>/) {a[$1];} next} {if($0 ~ /^>/) {header=($1 in a)}} header' ${output_dir}/${file}.fa ${file_path} > ${predicted_dir}/${file}.fa
}

# Loop atrav�s de todos os arquivos .fa no diret�rio de entrada fornecido pelo usu�rio
for file_path in ${input_dir}/*.fa
do
  # Processa o arquivo em background
  process_file "$file_path" &
  
  # Controla o n�mero de processos simult�neos
  ((current_procs++))
  if [ "$current_procs" -ge "$max_procs" ]; then
    wait # Aguarda a conclus�o dos processos antes de iniciar novos
    current_procs=0
  fi
done

# Aguarda que todos os processos em background terminem
wait
