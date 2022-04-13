#!/bin/bash

if [ ! -d "OSTEP" ]
then
    mkdir -p OSTEP
    mkdir -p ./OSTEP/numbered
    mkdir -p ./OSTEP/not-numbered
fi

echo "Finding the pdf links"

curl -silent https://pages.cs.wisc.edu/~remzi/OSTEP/ | grep  -o "<small>[0-9]*" | grep -o "[0-9]*" > ./OSTEP/order.txt
curl -silent https://pages.cs.wisc.edu/~remzi/OSTEP/ | grep "<small>[0-9]*" | grep -o "href=.*\.pdf" | sed "s/href=//" | sed "s/^/https:\/\/pages.cs.wisc.edu\/~remzi\/OSTEP\//" > ./OSTEP/pdf-list-number.txt
curl -silent https://pages.cs.wisc.edu/~remzi/OSTEP/ | sed "/<small>/d" | grep -o "href=.*\.pdf" | sed "s/href=//" | sed "s/^/https:\/\/pages.cs.wisc.edu\/~remzi\/OSTEP\//" > ./OSTEP/pdf-list-not.txt

i=1
line=""

echo "Downloading the pdfs"

while read pdf
do
    line=$(sed -n "${i}p" ./OSTEP/order.txt)
    wget --quiet $pdf -O ./OSTEP/numbered/${line}.pdf
    i=$((i+1))
done < ./OSTEP/pdf-list-number.txt

while read pdf
do
    wget --quiet $pdf -P ./OSTEP/not-numbered
done < ./OSTEP/pdf-list-not.txt

echo "Uniting the pdfs"

pdfunite ./OSTEP/not-numbered/preface.pdf ./OSTEP/not-numbered/toc.pdf ./OSTEP/OSTEP-init.pdf
sed -i '/preface.pdf/d' ./OSTEP/pdf-list-not.txt
sed -i '/toc.pdf/d' ./OSTEP/pdf-list-not.txt

i=1
c=2

for number in $(sort -n ./OSTEP/order.txt)
do
    if [ $i -eq 1 ]
    then
        pdfunite ./OSTEP/OSTEP-init.pdf ./OSTEP/numbered/${number}.pdf ./OSTEP/OSTEP-mid-${i}.pdf
    fi
    pdfunite ./OSTEP/OSTEP-mid-${i}.pdf ./OSTEP/numbered/${number}.pdf ./OSTEP/OSTEP-mid-${c}.pdf
    rm ./OSTEP/OSTEP-mid-${i}.pdf ./OSTEP/numbered/${number}.pdf
    i=$((i+1))
    c=$((c+1))
done

highest=./OSTEP/OSTEP-mid-${i}.pdf
i=1
c=2

for str in $(cat ./OSTEP/pdf-list-not.txt | sed "s/https:\/\/pages.cs.wisc.edu\/~remzi\/OSTEP\///")
do
    if [ $i -eq 1 ]
    then
        pdfunite ${highest} ./OSTEP/not-numbered/${str} ./OSTEP/OSTEP-final-${i}.pdf
    fi
    pdfunite ./OSTEP/OSTEP-final-${i}.pdf ./OSTEP/not-numbered/${str} ./OSTEP/OSTEP-final-${c}.pdf
    rm ./OSTEP/OSTEP-final-${i}.pdf ./OSTEP/not-numbered/${str}
    i=$((i+1))
    c=$((c+1))
done

highest=$(find ./ -name 'OSTEP-final*' | sort -n | tail -1)
mv $highest ./OSTEP.pdf
rm -r ./OSTEP

echo "Done!"
