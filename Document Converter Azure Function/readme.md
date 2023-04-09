# Word to PDF converter Azure Function
Creation of Function App Resources through Terraform and hosting of a PDF converter .Net core Application on top of the function. Github actions used to deploy Infrastructure and Application through the touch of a button in Github.

## .Net Core PDF Converter Application Description
Converts Microsoft Word Documents to PDF Files. Application is written in .Net core with an HTTPTrigger. Syncfusion Nugget package is used to convert Word Document to PDF. Sync Fusion is widely used by companys like Apple, IMB, and Visa to integrate productivity features into their hosted web applications. Microsoft OpenApi is the UI currently responsible for the front end of the application for uploading the Word document and downloading of the PDF files. Plan on creating a more customized UI in future versions of the APP.


## Resources created in Terraform Template
* Storage Account: Storage for Application data

* Service Plan: Consumption service plan for function app

* Windows Function App: Azure Function that runs/hosts the PDF converter code.

## How To Deploy For Yourself Using Github Actions

* Fork Repository from the main repo in the link

https://github.com/zacaryfettig/Document-Converter-Azure-Function

* Follow instructions in Deployment Instructions document

https://github.com/zacaryfettig/Terraform-Templates/blob/main/Document%20Converter%20Azure%20Function/Document%20Converter%20Deployment%20Instructions.pdf
