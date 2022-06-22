choco install anaconda3 -y --params '"/AddToPath /D:c:\Tools"'
choco install sql-server-express -y 
choco install sql-server-management-studio -y
choco install mysql -y 
choco install mysql.workbench -y 
#choco install postgresql13 --params '/Password:Passw0rd! /Port:5433' --ia '--enable-components server'
choco install sqlite -y 

pip install -r python.req

git clone https://github.com/devrbarr/datasets d:\datasets
rm -Recurse -Force d:\datasets\.git