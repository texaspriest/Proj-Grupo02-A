BIN='../a.out'
FILES=../*.ppm
OUTPUT='../OutputSEQppm.txt'

MAX=10
TIME=$(date +"%T")


echo "Inicio Teste MPI - $TIME\n"
echo "Teste Saidas MPI - $TIME" > $OUTPUT

for f in $FILES
do
	echo $f >> $OUTPUT
	echo "Testando arquivo $f"
	for i in `seq 1 $MAX`
	do
		echo "Saida $i" >> $OUTPUT
		
		echo "$f" | $BIN >> $OUTPUT
		echo "Teste $i Completo" 
	done
echo "\n" >> $OUTPUT
done
TIME=$(date +"%T")
echo "Fim Teste $TIME\n"
