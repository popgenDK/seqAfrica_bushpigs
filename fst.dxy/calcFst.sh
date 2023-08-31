#Get Fst - pop-level  
outputfile=$1
for i in `ls -1 $sfsdir/*.sfs` #Winsfs output
do
rows=`cat $i | grep '#' | sed 's/#SHAPE=<//' | sed 's/>//' | cut -f1 -d "/"`
cols=`cat $i | grep '#' | sed 's/#SHAPE=<//' | sed 's/>//' | cut -f2 -d "/"`
out=`basename $i .sfs`

echo $cols $rows $out
Rscript fstFrom2DSFS.R $i $out $cols $rows >> $outputfile
done

