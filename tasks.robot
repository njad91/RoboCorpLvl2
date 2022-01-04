*** Settings ***
Documentation     Robot That Orders Robots From RobotSparePartsBin Industries
...                Fills In Form
...                Submits Order
...                Saves Recipte and BotImage 

Library            RPA.Browser.Selenium        auto_close=${FALSE}
Library            RPA.HTTP
Library            RPA.Tables
Library            RPA.PDF
Library            RPA.Archive
Library            RPA.FileSystem
Library            RPA.Dialogs
Library            RPA.Robocorp.Vault

*** Tasks ***
Order robots from RobotSparePartsBin Industries Inc
    [Setup]     Open RobotOrderWebsite
    ${dtRobotOrders}=    Get orders
    FOR    ${row}    IN            @{dtRobotOrders}
        Fill In Order              ${row}
        Preview robot
        Submit the Order
        ${receipetPath}=         Export recipet as PDF      ${row}[Order number]   
        ${BotScreenshotPath}    Get Bot Screenshot         ${row}[Order number]
        Embed BotScreenShot in receipt PDF    ${receipetPath}    ${BotScreenshotPath}    ${row}[Order number]
        Order Another robot
    END
    Archive Receipts
    [Teardown]    Close Browser
    
Minimal task
    Log     Done.

*** Keywords ***
Get orders
    Add text input    URL
    Add submit buttons   OK
    ${Results}=    Run dialog
    Clear elements
    RPA.HTTP.Download            ${Results.URL}    overwrite=True
    ${dtBotOrders}=     Read table from CSV     orders.csv    header=True
    [Return]    ${dtBotOrders}

Open RobotOrderWebsite
    ${vSecret}=    Get Secret     RoboCorp2
    Open Available Browser        ${vSecret}[url]

                
Fill In Order
    [Arguments]    ${rowBotOrder}
    Wait Until Page Contains Element    css:div.modal-header
    Click Button                        OK
    Select From List By Index     id:head                                                ${rowBotOrder}[Head]
    Select Radio Button           body                                                   ${rowBotOrder}[Body]
    input text                    xpath://label[contains(.,'3. Legs:')]/../input         ${rowBotOrder}[Legs]
    Input Text                    id:address                                             ${rowBotOrder}[Address]
    
Preview robot
    Click Button    id:preview    




Export recipet as PDF
    [Arguments]    ${OrderNumber}
    Wait Until Element Is Visible    id:receipt
    ${sales_results_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf     ${sales_results_html}    ${OUTPUT_DIR}${/}Temp${/}receipt_${OrderNumber}.pdf
    [return]        ${OUTPUT_DIR}${/}Temp${/}receipt_${OrderNumber}.pdf

Submit The Order
    Wait Until Keyword Succeeds    5x    0.5s    
    ...    click submit button and wait

click submit button and wait
    Click Button    id:order
    Wait Until Page Contains Element    id:receipt

Get Bot Screenshot    
    [Arguments]    ${OrderNumber}
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}Temp${/}botImage_${OrderNumber}.png
    [Return]      ${OUTPUT_DIR}${/}${/}Temp${/}botImage_${OrderNumber}.png

Embed BotScreenShot in receipt PDF
    [Arguments]    ${pdfPath}    ${BotScreenshotPath}    ${OrderNumber}
    Open Pdf    ${pdfPath}
    Add Watermark Image To Pdf    ${BotScreenshotPath}    ${OUTPUT_DIR}${/}FinalReceipt${/}FinalReceipt_${OrderNumber}.pdf
    Close Pdf
    ${filesToMove}=     Create List         ${pdfPath}    ${BotScreenshotPath}
    Remove Directory      ${OUTPUT_DIR}${/}Temp    recursive=True


Order Another robot
    Click Button    id:order-another
Archive Receipts
    Archive Folder With Zip    ${OUTPUT_DIR}${/}FinalReceipt    ${OUTPUT_DIR}${/}Receipts.zip 
    Remove Directory           ${OUTPUT_DIR}${/}FinalReceipt    recursive=True
