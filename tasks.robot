*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the order screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.Desktop
Library             XML
Library             RPA.Word.Application
Library             RPA.FileSystem
Library             RPA.PDF
Library             Collections
Library             RPA.Archive
Library             RPA.RobotLogListener
Library             RPA.Excel.Files


*** Variables ***
${GLOBAL_RETRY_AMOUNT}=         9x
${GLOBAL_RETRY_INTERVAL}=       3s


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Close the order site modal
    Read the orders file and loop through it
    Package Orders
    Wrap up


*** Keywords ***
Open the robot order website
    List Directories In Directory
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Close the order site modal
    Click Button    css:.btn-dark

Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${orders}=    Read table from CSV    orders.csv
    ${rows}    ${columns}=    Get Table Dimensions    ${orders}
    RETURN    ${orders}

Read the orders file and loop through it
    Mute Run On Failure    Save robot details
    ${orders}=    Get orders
    FOR    ${order}    IN    @{orders}
        Fill in an order    ${order}
        Submit an order    ${order}
    END
    RETURN    ${orders}

Fill in an order
    [Arguments]    ${order}
    &{order_dict}=    Create Dictionary    &{order}
    Select From List By Value    id:head    ${order_dict.Head}
    Select Radio Button    body    ${order_dict.Body}
    Input Text    css:input[placeholder="Enter the part number for the legs"]    ${order_dict.Legs}
    Input Text    id:address    ${order_dict.Address}

Submit an order
    [Arguments]    ${order}
    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${GLOBAL_RETRY_INTERVAL}    Click order button    ${order}

Click order button
    [Arguments]    ${order}
    TRY
        Click Button    id:order
        Save robot details    ${order}
        Click Button    id:order-another
    EXCEPT
        Click Button    id:order-another
    FINALLY
        Click Button    css:.btn-dark
    END

Save robot details
    [Arguments]    ${order}
    ${order_number}=    Get From Dictionary    ${order}    Order number
    Wait Until Element Is Visible    id:receipt
    Wait Until Element Is Visible    id:robot-preview-image
    ${receipt_html}=    RPA.Browser.Selenium.Get Element Attribute    id:receipt    outerHTML
    Screenshot
    ...    id:robot-preview-image
    ...    ${OUTPUT_DIR}${/}temp${/}preview_${order_number}.png
    Build PDF receipt    ${receipt_html}    ${order_number}
    Add preview to PDF    ${order_number}

Build PDF receipt
    [Arguments]    ${receipt_html}    ${order_number}
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}temp${/}order_${order_number}.pdf    margin=20

Add preview to PDF
    [Arguments]    ${order_number}
    Add Watermark Image To Pdf
    ...    image_path=${OUTPUT_DIR}${/}temp${/}preview_${order_number}.png
    ...    output_path=${OUTPUT_DIR}${/}temp${/}order_${order_number}.pdf
    ...    source_path=${OUTPUT_DIR}${/}temp${/}order_${order_number}.pdf
    ...    coverage=0.18
    Close Pdf
    Remove File    ${OUTPUT_DIR}${/}temp${/}preview_${order_number}.png

Package Orders
    Archive Folder With Zip    ${OUTPUT_DIR}${/}temp${/}    ${OUTPUT_DIR}${/}orders.zip
    Remove Directory    ${OUTPUT_DIR}${/}temp${/}    recursive=${True}

Wrap up
    Close Browser
