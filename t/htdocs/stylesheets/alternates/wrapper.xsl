<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">


<xsl:template match="/html/body">
    <body>
        <div class="header"><p>Header</p></div>
            <xsl:copy-of select="./*"/>
        <div class="footer"><p>Footer</p></div>
    </body>
</xsl:template>

</xsl:stylesheet>
