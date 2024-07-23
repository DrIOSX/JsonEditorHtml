<#
    .SYNOPSIS
        Converts JSON content to an HTML file with an embedded JSON editor.
    .DESCRIPTION
        The ConvertTo-JsonEditorHtml function takes JSON content from a file or a string and generates an HTML file that includes an embedded JSON editor. The HTML file allows the user to view and edit the JSON content, as well as export it to CSV, Excel, and PDF formats. The function supports both file path and direct JSON string inputs.
    .PARAMETER JsonFilePath
        The path to the JSON file to be converted. This parameter is mandatory if JsonString is not provided.
    .PARAMETER JsonString
        The JSON string to be converted. This parameter is mandatory if JsonFilePath is not provided.
    .PARAMETER OutputHtmlFilePath
        The path where the output HTML file will be saved. This parameter is mandatory.
    .OUTPUTS
        None. This function does not output any objects.
    .EXAMPLE
        ConvertTo-JsonEditorHtml -JsonFilePath "C:\path\to\file.json" -OutputHtmlFilePath "C:\path\to\output.html"
        This example reads JSON content from the specified file and generates an HTML file with an embedded JSON editor.
    .EXAMPLE
        $jsonString = '{"key": "value"}'
        ConvertTo-JsonEditorHtml -JsonString $jsonString -OutputHtmlFilePath "C:\path\to\output.html"
        This example takes a JSON string and generates an HTML file with an embedded JSON editor.
    .NOTES
        This function uses the following third-party libraries:
        - JSONEditor (Apache License 2.0)
            - Link: https://cdnjs.cloudflare.com/ajax/libs/jsoneditor/10.1.0/jsoneditor.min.js
            - Source: https://github.com/josdejong/jsoneditor
        - Prism (MIT License)
            - Link: https://cdnjs.cloudflare.com/ajax/libs/prism/1.27.0/prism.min.js
            - Source: https://github.com/PrismJS/prism
        - FileSaver.js (MIT License)
            - Link: https://cdnjs.cloudflare.com/ajax/libs/FileSaver.js/2.0.5/FileSaver.min.js
            - Source: https://github.com/eligrey/FileSaver.js
        - xlsx.js (Apache License 2.0)
            - Link: https://cdnjs.cloudflare.com/ajax/libs/xlsx/0.18.5/xlsx.full.min.js
            - Source: https://github.com/SheetJS/sheetjs
        - jsPDF (MIT License)
            - Link: https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.4.0/jspdf.umd.min.js
            - Source: https://github.com/parallax/jsPDF
        Author: DrIOSX
        Date: 07/21/2024
#>
function ConvertTo-JsonEditorHtml {
    [CmdletBinding()]
    [OutputType([void])]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ParameterSetName = 'FilePath',
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$JsonFilePath,
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ParameterSetName = 'Default',
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$JsonString,
        [Parameter(Mandatory = $true)]
        [string]$OutputHtmlFilePath
    )
    process {
        # Read JSON content from the specified file
        if ($PSCmdlet.ParameterSetName -eq 'FilePath') {
            if (-Not (Test-Path -Path $JsonFilePath)) {
                throw "The file '$JsonFilePath' does not exist."
            }
            $jsonContent = Get-Content -Path $JsonFilePath -Raw
        }
        # Use the provided JSON string
        else {
            $jsonContent = $JsonString
        }
        # Escape special characters in JSON content for embedding in HTML
        $escapedJsonContent = $jsonContent -replace "'", "&#39;"
        # HTML Template
        # Prism 1.29.0 > v1.29.0
        #
        $htmlTemplate = @'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><!--titleContent--></title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/jsoneditor/10.1.0/jsoneditor.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/themes/prism-tomorrow.min.css">
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jsoneditor/10.1.0/jsoneditor.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/prism.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-json.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/FileSaver.js/2.0.5/FileSaver.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/xlsx/0.18.5/xlsx.full.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
    <style>
        body { font-family: Arial, sans-serif; }
        #jsoneditor { height: 600px; margin-bottom: 20px; }
        pre { background-color: #2d2d2d; color: #f8f8f2; padding: 10px; border-radius: 5px; }
        .buttons { margin-bottom: 20px; }
    </style>
</head>
<body>
    <h1>Enhanced JSON Editor</h1>
    <div class="buttons">
        <button id="exportCSV">Export to CSV</button>
        <button id="exportExcel">Export to Excel</button>
        <button id="exportPDF">Export to PDF</button>
    </div>
    <div id="jsoneditor"></div>
    <pre id="prettyJson"><code class="language-json"></code></pre>

    <script>
        const container = document.getElementById('jsoneditor');
        const options = {
            mode: 'code',
            onChange: updatePrettyJson
        };
        const editor = new JSONEditor(container, options);

        const json = <!--escapedJsonContent-->;

        editor.set(json);

        // Function to update pretty JSON
        function updatePrettyJson() {
            const updatedJson = editor.get();
            const prettyJson = JSON.stringify(updatedJson, null, 2);
            document.getElementById('prettyJson').innerHTML = Prism.highlight(prettyJson, Prism.languages.json, 'json');
        }

        // Initial pretty print
        updatePrettyJson();

        // Function to flatten JSON
        function flattenJson(data, parentKey = '', result = {}) {
            for (let key in data) {
                if (data.hasOwnProperty(key)) {
                    const newKey = parentKey ? `${parentKey}.${key}` : key;
                    if (typeof data[key] === 'object' && data[key] !== null && !Array.isArray(data[key])) {
                        flattenJson(data[key], newKey, result);
                    } else if (Array.isArray(data[key])) {
                        data[key].forEach((item, index) => {
                            flattenJson(item, `${newKey}.${index + 1}`, result);
                        });
                    } else {
                        result[newKey] = data[key];
                    }
                }
            }
            return result;
        }

        // Export JSON to CSV
        document.getElementById('exportCSV').addEventListener('click', function () {
            const json = editor.get();
            const flatJson = flattenJson(json);
            const keys = Object.keys(flatJson);
            let csv = '"Key","Value"\n';

            keys.forEach(key => {
                csv += `"${key}","${flatJson[key]}"\n`;
            });

            const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
            saveAs(blob, 'data.csv');
        });

        // Export JSON to Excel
        document.getElementById('exportExcel').addEventListener('click', function () {
            const json = editor.get();
            const flatJson = flattenJson(json);
            const worksheetData = Object.keys(flatJson).map(key => ({
                Key: key,
                Value: flatJson[key]
            }));
            const worksheet = XLSX.utils.json_to_sheet(worksheetData);
            const workbook = XLSX.utils.book_new();
            XLSX.utils.book_append_sheet(workbook, worksheet, 'Sheet1');
            XLSX.writeFile(workbook, 'data.xlsx');
        });

        // Export JSON to PDF
        document.getElementById('exportPDF').addEventListener('click', function () {
            const { jsPDF } = window.jspdf;
            const doc = new jsPDF();
            const json = editor.get();
            const prettyJson = JSON.stringify(json, null, 2);

            doc.setFontSize(10);
            doc.text(prettyJson, 10, 10);
            doc.save('data.pdf');
        });
    </script>
</body>
</html>
'@
        $htmlTemplate = $htmlTemplate -replace '<!--titleContent-->', "$JsonFilePath"
        $htmlTemplate = $htmlTemplate -replace '<!--escapedJsonContent-->', "$escapedJsonContent"
        # Write the HTML content to the specified output file
        $htmlTemplate | Out-File -FilePath $OutputHtmlFilePath -Encoding utf8
        #Set-Content -Path $OutputHtmlFilePath -Value $htmlTemplate
        Write-Verbose "HTML file has been generated at '$OutputHtmlFilePath'."
    }
}