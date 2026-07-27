<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:wix="http://schemas.microsoft.com/wix/2006/wi">

    <xsl:output method="xml" indent="yes" />

    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:key name="service-search" match="wix:Component[contains(wix:File/@Source, 'Jami.exe')]" use="@Id" />
    <xsl:key name="pdb-search" match="wix:Component[contains(wix:File/@Source, '.pdb')]" use="@Id" />
    <!-- ponytail: Qt 6.10.3's windeployqt bundles icuuc.dll, an ICU stub
         that requires the full icu.dll (never shipped), breaking startup
         on older Windows (10 LTSC 2019, Server 2019). Exclude it like pdbs. -->
    <xsl:key name="icu-search" match="wix:Component[contains(wix:File/@Source, 'icuuc.dll')]" use="@Id" />

    <xsl:template match="wix:Component[key('service-search', @Id)]" />
    <xsl:template match="wix:Component[key('pdb-search', @Id)]" />
    <xsl:template match="wix:Component[key('icu-search', @Id)]" />

    <xsl:template match="wix:ComponentRef[key('service-search', @Id)]" />
    <xsl:template match="wix:ComponentRef[key('pdb-search', @Id)]" />
    <xsl:template match="wix:ComponentRef[key('icu-search', @Id)]" />

</xsl:stylesheet>