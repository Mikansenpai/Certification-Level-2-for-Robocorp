*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library    RPA.Browser.Selenium    auto_close=${False}
Library    RPA.HTTP
Library    RPA.Excel.Files
Library    RPA.Tables
Library    RPA.Robocorp.WorkItems
Library    RPA.Desktop
Library    RPA.Robocorp.Process
Library    RPA.RobotLogListener
Library    RPA.Excel.Application
Library    RPA.PDF
Library    RPA.Archive
*** Tasks ***
*** Keywords ***
Open The Robot Order Website
    Open Available Browser       https://robotsparebinindustries.com/#/robot-order
​
***Keywords***
Get Orders
    Download        https://robotsparebinindustries.com/orders.csv      overwrite=True
    ${orders}=      Read Table From CSV     orders.csv
    [Return]        ${orders}
​
***Keywords***
Close the annoying modal
    Click Button        OK
    Run Keyword And Ignore Error    Click Button        OK
​***Keywords***
Fill the form
    [Arguments]     ${row}
    ${Head_as_string}=      Convert To String    ${row}[Head]
    Select From List By Value    head       ${Head_as_string} 
    Input Text      address     ${row}[Address]
    Input Text      class:form-control    ${row}[Legs]
    Click button    ${row}[Body]
​
​
***Keywords***
Preview the robot
    Click Button    id:preview
​
***Keywords***
Submit the order
    Click Button    id:order
    Run Keyword And Ignore Error    Click Button    id:order
    Sleep       5 sec
     Click Element If Visible   id:order​
***Keywords***
Store the receipt as a PDF file
    [Arguments]     ${order_nums}
    ${Receipt_in_html}=     Get Element Attribute       id:receipt      outerHTML
    Html To Pdf     ${Receipt_in_html}      ${CURDIR}${/}PDF${/}${order_nums}.pdf
    ${pdf}=     set variable    ${CURDIR}${/}PDF${/}${order_nums}.pdf
    [return]    ${pdf}
​
***Keywords***
Take a screenshot of the robot
    [Arguments]     ${order_num}
    Screenshot      id:robot-preview-image      ${CURDIR}${/}output${/}${order_num}.png
    ${screenshot}=     set variable     ${CURDIR}${/}output${/}${order_num}.png
    [return]    ${screenshot}
​
***Keywords***
Embed the robot screenshot to the receipt PDF file
    [Arguments]     ${screenshot}       ${pdf}
    Open Pdf    ${pdf}
    Add watermark Image To Pdf    ${screenshot}   ${pdf}
    Close Pdf   ${pdf}
​
*** Tasks ***
Order the robot from the given details
    Open The Robot Order Website
    ${orders}=      Get Orders
     FOR    ${row}    IN    @{orders}
         Close the annoying modal
         Fill the form    ${row}
         Preview the robot
         Run Keyword And Continue on failure      Submit the order
         ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
         ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
         Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Click Button    id:order-another
     END
     ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
     Archive Folder With Zip  ${CURDIR}${/}pdf    ${zip_file_name}
    