# Word to PDF converter Azure Function - Build Out in Progress
Creation of Function App Resources through Terraform and hosting a PDF converter .Net core Application on top of the function. Github actions used to deploy Infrastructure and Application through the touch of a button in Github.

## Dot Net PDF Converter Application Description
Converts Microsoft Word Documents to PDF Files. Application is written in .Net core with an HTTPTrigger. Syncfusion Nugget package is used to convert Word Document to PDF. Sync Fusion is widely used by companys like Apple, IMB, and Visa to integrate productivity features into their hosted web applications. Microsoft OpenApi is the UI currently responsible for the front end of the application for uploading the Word document and downloading of the PDF file. Plan on creating a more customized UI in future versions of the APP.


## Resources created in Terraform Template
* Storage Account: Storage for Application data

* Service Plan: Consumption service plan for function app

* Windows Function App: Azure Function that runs/hosts the PDF converter code
