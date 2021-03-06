<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
	xmlns:path="tag:conaltuohy.com,2018:nma/trix-path-traversal"
	xmlns:trix="http://www.w3.org/2004/03/trix/trix-1/">
	
	<xsl:param name="root-resource"/><!-- e.g. "http://nma-dev.conaltuohy.com/xproc-z/narrative/1758#" -->
	<xsl:param name="debug" select=" 'false' "/><!-- 'true' will log the various of the redacted triples --> 
	<xsl:import href="util/trix-traversal-functions.xsl"/>
	
	<xsl:variable name="graph" select="/trix:trix/trix:graph" />
	
	<xsl:variable name="aat-ns" select=" 'http://vocab.getty.edu/aat/' "/> 
	<xsl:variable name="rdf-ns" select=" 'http://www.w3.org/1999/02/22-rdf-syntax-ns#' "/> 
	<xsl:variable name="ore-ns" select=" 'http://www.openarchives.org/ore/terms/' "/> 
	<xsl:variable name="dc-ns" select=" 'http://purl.org/dc/terms/' "/> 
	<xsl:variable name="rdfs-ns" select=" 'http://www.w3.org/2000/01/rdf-schema#' "/> 
	<xsl:variable name="crm-ns" select=" 'http://www.cidoc-crm.org/cidoc-crm/' "/>
	<xsl:variable name="nma-term-ns" select="replace($root-resource, '([^/]+//[^/]+).*', '$1/term/')"/>

	<!-- Objects within narratives have certain properties which we always want to retain: -->
	<xsl:variable name="desired-narrative-object-predicates" select="
		(
			concat($rdf-ns, 'type'),
			concat($rdfs-ns, 'label'),
			concat($crm-ns, 'P70i_is_documented_in')						
		)
	"/>	
	
	<xsl:key name="representations-by-object-id"
		match="/trix:trix/trix:graph/trix:triple[*[2]='http://www.cidoc-crm.org/cidoc-crm/P138i_has_representation']"
		use="*[1]"
	/>	
	
	<xsl:template match="/">
		<xsl:if test="$debug='true'">
			<xsl:message>redacting low quality images...</xsl:message>
		</xsl:if>
		<xsl:call-template name="do-redaction" />
	</xsl:template>
	
	<xsl:template name="do-redaction">
		<trix xmlns="http://www.w3.org/2004/03/trix/trix-1/">
			<graph>
				<!-- Find the identifiers of all the physical objects in the graph -->
				<xsl:variable name="objects" select="path:backward(concat($crm-ns, 'E19_Physical_Object'), 'rdf:type')"/>

				<!-- ############################################################################## -->
				<!-- Having good quality images from Piction means we don't need any images from EMu -->
				
				<!-- identify any objects which have Piction images -->
				<xsl:variable name="objects-with-piction-images" select="
					$objects
						[
							path:forward(., ('crm:P138i_has_representation', 'crm:P2_has_type'))
								[
									contains(., 'piction-image')
								]
						]
				"/>
				<!-- identify any EMu images which can therefore be discarded -->
				<xsl:variable name="unwanted-emu-images" select="
					key('representations-by-object-id', $objects-with-piction-images)
						[
							path:forward(*[3], 'crm:P2_has_type')
								[contains(., 'emu-image')]
						]
				"/>

				<!-- ############################################################################## -->
				<!-- Finally copy the triples of the graph, excluding any of the triples we've identified as unwanted -->
				<xsl:variable name="published-triples" select="$graph/trix:triple except $unwanted-emu-images"/>
				
				<xsl:call-template name="debug-list-redacted-triples">
					<xsl:with-param name="reason">unwanted emu images</xsl:with-param>
					<xsl:with-param name="redaction" select="$unwanted-emu-images"/>
				</xsl:call-template>

				<!-- sort the triples into a stable order, to facilitate checking for changes later in the pipeline -->
				<!-- NB trix:id elements (blank nodes) are not used for sorting since their values are not stable -->
				<xsl:for-each select="$published-triples">
					<xsl:sort select="*[1]/self::trix:uri"/>
					<xsl:sort select="*[2]"/>
					<xsl:sort select="*[3]/self::trix:plainLiteral"/>
					<xsl:sort select="*[3]/self::trix:plainLiteral/@xml:lang"/>
					<xsl:sort select="*[3]/self::trix:typedLiteral"/>
					<xsl:sort select="*[3]/self::trix:typedLiteral/@dataType"/>
					<xsl:copy-of select="."/>
				</xsl:for-each>
				
			</graph>
		</trix>
	</xsl:template>
	
	<xsl:template name="debug-list-redacted-triples">
		<xsl:param name="reason"/>
		<xsl:param name="redaction"/>
		<xsl:if test="($debug = 'true') and $redaction">
			<xsl:message>Redacting: <xsl:value-of select="$reason"/></xsl:message>
			<xsl:for-each select="$redaction">
				<xsl:message><xsl:value-of select="string-join(*, ' ')"/></xsl:message>
			</xsl:for-each>
		</xsl:if>
	</xsl:template>
	
</xsl:stylesheet>
