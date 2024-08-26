# Define the path and encryption key
$path = "C:\Users\explorer\Documents\Encrypt"
$encryptionKey = "JWMUgn6nR/qt77ia9VzoXgtmGAU3m58+x2oabOzIDN8=" # 32-byte key in Base64 format

# Decode the key from Base64 to bytes
$keyBytes = [System.Convert]::FromBase64String($encryptionKey)

# Check key length
$keyLength = $keyBytes.Length
if ($keyLength -ne 32) {
    throw "The key must be 32 bytes long for AES-256 encryption. Current key length: $($keyLength) bytes."
}

# Function to encrypt data
function Encrypt-Data {
    param (
        [byte[]]$data,
        [byte[]]$key
    )

    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $key
    $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7

    $iv = [byte[]]::new(16) # Initialization vector
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($iv)
    $aes.IV = $iv

    $encryptor = $aes.CreateEncryptor()

    $encryptedData = $encryptor.TransformFinalBlock($data, 0, $data.Length)
    $aes.Dispose()

    # Combine IV and encrypted data
    return $iv + $encryptedData
}

# Process each file in the directory
Get-ChildItem -Path $path -File | ForEach-Object {
    $filePath = $_.FullName
    $fileName = $_.Name
    $newFilePath = Join-Path -Path $path -ChildPath ($fileName + ".enc")

    Write-Host "Processing file: $filePath"
    Write-Host "Encrypting and saving to: $newFilePath"

    try {
        # Read the file content
        $fileContent = [System.IO.File]::ReadAllBytes($filePath)
        
        # Encrypt the content
        $encryptedContent = Encrypt-Data -data $fileContent -key $keyBytes
        
        # Create a new file with the encrypted content
        [System.IO.File]::WriteAllBytes($newFilePath, $encryptedContent)

        # Remove the original file
        Remove-Item -Path $filePath -Force

        Write-Host "File encrypted and replaced successfully: $newFilePath"
    } catch {
        Write-Host ("Error processing file " + $filePath + ": " + $_.Exception.Message)
    }
}

Write-Host "Encryption and replacement completed."