<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:param name="testparam"/>

<xsl:template match="/shop">
    <html>
        <body>
            <h1>Hello Shopper!</h1>
            <p><xsl:value-of select="$testparam"/></p>
            <p><xsl:copy-of select="./*"/></p>
        </body>
    </html>
</xsl:template>

</xsl:stylesheet>
