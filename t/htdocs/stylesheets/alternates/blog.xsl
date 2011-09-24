<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:param name="testparam"/>

<xsl:template match="/blog">
    <html>
        <body>
            <h1>Hello DFH!</h1>
            <p><xsl:value-of select="$testparam"/></p>
            <p><xsl:copy-of select="./*"/></p>
        </body>
    </html>
</xsl:template>

</xsl:stylesheet>
