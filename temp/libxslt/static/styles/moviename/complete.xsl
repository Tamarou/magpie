<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="params.xsl"/>
<xsl:output method="html"/>

<xsl:template match="/">
  <html>
  <head>
    <title>Movie Star Name Generator</title>
  </head>
  <body>
  <div class="pagehead">
    Movie Star Name Generator
  </div>
  <div class="message">
    <p>
      <xsl:apply-templates select="//message"/>
    </p>
  </div>
  <xsl:apply-templates select="/application"/>
  <div class="pagefoot">
    Copyright 1994-2003 WebCliche, Inc. All rights reserved.
  </div>
</body>
</html>
</xsl:template>

<xsl:template match="application">
   <div>
     <p>
       Your new <i>nom d'cinema</i> is: 
       <b>
         <xsl:value-of select="/application/first_name"/>
         <xsl:text> </xsl:text>
         <xsl:value-of select="/application/last_name"/>
       </b>
     </p>
    </div>
    <form name="prompt" action="libxslt" method="post">
      <input name="last.hotel" type="hidden" value="{$last.hotel}"/>
      <input name="last.street" type="hidden" value="{$last.street}"/>
      <input name="last.maiden" type="hidden" value="{$last.maiden}"/>
      <input name="first.middle_name" type="hidden" value="{$first.middle_name}"/>
      <input name="first.pet" type="hidden" value="{$first.pet}"/>
      <input name="first.car" type="hidden" value="{$first.car}"/>
      <input name="appstate" type="hidden" value="complete"/>
      <div>
        <input type="submit" value="Regenerate"/>
        <input type="button" value="Start Over" onClick="location='libxslt'"/>
      </div>
    </form>
</xsl:template>

</xsl:stylesheet>