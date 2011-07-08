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
    <form name="prompt" action="libxslt" method="post">
      <div class="appmain">
        <div>
          Name of classy hotel: 
          <input name="last.hotel" type="text" value="{$last.hotel}"/>
        </div>
        <div>
          Name a street you lived on when you were a teenager: 
          <input name="last.street" type="text" value="{$last.street}"/>
        </div>
        <div>
          Your mother's maiden name: 
          <input name="last.maiden" type="text" value="{$last.maiden}"/>
        </div>
        <div>
          Your middle name: 
          <input name="first.middle_name" type="text" value="{$first.middle_name}"/>
        </div>
        <div>
          The name of your favorite pet: 
          <input name="first.pet" type="text" value="{$first.pet}"/>
        </div>
        <div>
          Name of your favorite model of car: 
          <input name="first.car" type="text" value="{$first.car}"/>
        </div>
        <div>
          <input name="appstate" type="hidden" value="complete"/>
          <input name="complete" type="hidden" value="1"/>
          <input type="submit" value="Generate Name"/>
          <input type="reset" value="Start Over"/>
        </div>
      </div>
    </form>
</xsl:template>

</xsl:stylesheet>