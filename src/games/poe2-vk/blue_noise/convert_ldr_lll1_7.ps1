$url = "https://raw.githubusercontent.com/Calinou/free-blue-noise-textures/5fd5473e39c57ee4cd7aad3faa00ae0a97f76ab2/256_256/LDR_LLL1_7.png"

# Download the file bytes directly into RAM
$response = Invoke-WebRequest -Uri $url -UseBasicParsing
$bytes = $response.Content

# Convert bytes to hex strings 
# (Using a foreach loop here is much faster than the pipeline for 97KB of data)
$hex = foreach ($b in $bytes) { "0x{0:x2}" -f $b }
$array = $hex -join ", "

# Format the C++ header content
$content = "namespace blue_noise { inline constexpr unsigned char ldr_lll1_7[] = { " + $array + " }; }"

# Write the header file to disk
[System.IO.File]::WriteAllText("ldr_lll1_7.h", $content)