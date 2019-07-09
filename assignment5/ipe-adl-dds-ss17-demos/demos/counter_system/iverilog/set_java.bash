
echo "Java:"

javacL="/c/Program Files/Java/jdk1.8.0_112/bin/"

echo $(ls $javacL)
export PATH="$PATH:'/c/Program Files/Java/jdk1.8.0_112/bin'"
echo $(which javac)