*** Settings ***
Documentation     Orders robots from RobotSpareBin.
Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive


*** Variables ***
${URL}=    https://robotsparebinindustries.com/#/robot-order
${URL_csv}=     https://robotsparebinindustries.com/orders.csv

*** Keywords ***
Download the csv file
    Download    ${URL_csv}    overwrite=True

*** Keywords ***
Open orders website and fill the form
    Open Available Browser     ${URL}  
    ${orders}=    Read Table From Csv    orders.csv
    FOR    ${order}    IN    @{orders}
        Click Button    OK
        # Head
        Click Element    xpath=//select[@id="head"]
        Click Element    xpath=//option[@value="${order}[Head]"]
        # Body
        Click Element    xpath=//label[@for="id-body-${order}[Body]"]
        # Legs
        Input Text When Element Is Visible    xpath=//input[@placeholder="Enter the part number for the legs"]    ${order}[Legs]
        Input Text When Element Is Visible    xpath=//input[@placeholder="Shipping address"]    ${order}[Address]
        # Preview and order
        Click Button    Preview
        Click Button When Visible    xpath=//button[@id="order"]
        ${ref}    Does Page Contain Button    xpath=//button[@id="order-another"]
        IF    ${ref} == False
            FOR    ${i}    IN RANGE    10
                Click Button When Visible    xpath=//button[@id="order"]
                ${ref}    Does Page Contain Button    xpath=//button[@id="order-another"]
                Exit For Loop If    ${ref} == True
            END
        END
        
        # Store the receipt as a PDF file
        Wait Until Element Is Visible    id:receipt
        ${pdf}=    Get Element Attribute    id:receipt    outerHTML
        Html To Pdf    ${pdf}    ${CURDIR}${/}output${/}receipt_${order}[Order number].pdf
        
        # Take screenshot of robot image
        Screenshot    css:div.col-sm-5    ${CURDIR}${/}output${/}robot_${order}[Order number].png
        
        # Embed screenshot to PDF
        ${pdf_file}=    Open Pdf   ${CURDIR}${/}output${/}receipt_${order}[Order number].pdf
        ${screenshot}=    Create List
        ...    ${CURDIR}${/}output${/}receipt_${order}[Order number].pdf
        ...    ${CURDIR}${/}output${/}robot_${order}[Order number].png
        Add Files To Pdf    ${screenshot}    ${CURDIR}${/}output${/}receipt_screenshot_${order}[Order number].pdf
        
        # Order anoder robot
        Click Button When Visible    xpath=//button[@id="order-another"]
        
    END
    
    # Create ZIP file
    Archive Folder With Zip    output    output.zip
    
    Close All Browsers

*** Tasks ***
Order Robot
    Download the csv file
    Open orders website and fill the form
