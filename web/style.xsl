<?xml version="1.0" ?>
<!--
   XML stylesheet for formatting the navi-misc web site
-->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <!--================================== Document Root -->

  <xsl:template match="/page">
    <html>
      <head>
        <title>navi-misc : <xsl:value-of select="@title"/></title>
        <style type="text/css" media="all"> @import url(style.css);</style>
      </head>
      <body>
        <!--========== Heading -->
        <div class="heading">
          <div class="siteName">navi-misc</div>
          <div class="title"><xsl:value-of select="@title"/></div>
          <div class="subtitle"><xsl:value-of select="@subtitle"/></div>
	  <div class="headingTabs">
	    <a class="headingTab" href="index.xml">projects</a>
	    <a class="headingTab" href="http://navi.picogui.org/svn/misc">repository</a>
	  </div>
        </div>

	<table class="columns">

          <!--========== Navigation -->
	  <td class="left">
	    <div class="section">
              <div class="sectionTop">Projects</div>
              <div class="row">
                <ul>
		  <xsl:apply-templates select="document('projects.xml')//projects/project"/>
                </ul>
              </div>
            </div>
	  </td>

          <!--========== Content -->
	  <td class="main">
            <xsl:apply-templates select="introduction"/>
	  </td>

        </table>

        <!--========== Footer -->
        <div class="footer">
          <a href="/">
            <img src="http://navi.picogui.org/images/web/navi64.png" width="64" height="39" alt="Navi"/>
          </a>
        </div>

      </body>
    </html>
  </xsl:template>

  <!--================================== Projects -->

  <xsl:template match="project">
    <li>
      <a>
        <xsl:attribute name="href"><xsl:value-of select="@href"/></xsl:attribute>
        <xsl:value-of select="@name"/>
      </a>
      <ul>
        <xsl:apply-templates select="project"/>
      </ul>
    </li>
  </xsl:template>

  <!--================================== Introduction -->

  <xsl:template match="introduction">
    <span class="section">Introduction</span>
    <div class="section">
      <div class="sectionTop"/>
      <div class="row">
        <xsl:value-of select="."/>
      </div>
    </div>
  </xsl:template>

</xsl:stylesheet>
