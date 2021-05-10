#!/bin/bash

export PATH=/opt/IBM/node-v6.7.0/bin:$PATH

npm install -g newman
npm i npm@latest -g newman-reporter-html

newman run "https://www.getpostman.com/collections/8a0c9bc08f062d12dcda" -r html,cli --reporter-html-export /home/results/report.html &> newmanResults.txt

git checkout -f HTMLreports

cp ./newmanResults.txt ./test/results/newmanResults.txt

cp /home/results/report.html ./test/results/report.html

git add .

git config user.email gustaf.olsson@enfogroup.com
git config user.name GusOls

git commit -m "commit of latest test results html and newman result txt files"

git push origin HTMLreports
