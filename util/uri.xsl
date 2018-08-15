<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
	xmlns:uri="tag:conaltuohy.com,2018:nma/uri-utility">
	
	<xsl:function name="uri:is-uri">
		<xsl:param name="uri"/>
		<!-- http://jmrware.com/articles/2009/uri_regexp/URI_regex.html#uri-40 -->
		<xsl:variable name="uri-regex">
			^
			[A-Za-z][A-Za-z0-9+\-.]* :
			(?: //
			  (?: (?:[A-Za-z0-9\-._~!$&amp;'()*+,;=:]|%[0-9A-Fa-f]{2})* @)?
			  (?:
				\[
				(?:
				  (?:
					(?:                                                    (?:[0-9A-Fa-f]{1,4}:){6}
					|                                                   :: (?:[0-9A-Fa-f]{1,4}:){5}
					| (?:                            [0-9A-Fa-f]{1,4})? :: (?:[0-9A-Fa-f]{1,4}:){4}
					| (?: (?:[0-9A-Fa-f]{1,4}:){0,1} [0-9A-Fa-f]{1,4})? :: (?:[0-9A-Fa-f]{1,4}:){3}
					| (?: (?:[0-9A-Fa-f]{1,4}:){0,2} [0-9A-Fa-f]{1,4})? :: (?:[0-9A-Fa-f]{1,4}:){2}
					| (?: (?:[0-9A-Fa-f]{1,4}:){0,3} [0-9A-Fa-f]{1,4})? ::    [0-9A-Fa-f]{1,4}:
					| (?: (?:[0-9A-Fa-f]{1,4}:){0,4} [0-9A-Fa-f]{1,4})? ::
					) (?:
						[0-9A-Fa-f]{1,4} : [0-9A-Fa-f]{1,4}
					  | (?: (?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?) \.){3}
							(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)
					  )
				  |   (?: (?:[0-9A-Fa-f]{1,4}:){0,5} [0-9A-Fa-f]{1,4})? ::    [0-9A-Fa-f]{1,4}
				  |   (?: (?:[0-9A-Fa-f]{1,4}:){0,6} [0-9A-Fa-f]{1,4})? ::
				  )
				| [Vv][0-9A-Fa-f]+\.[A-Za-z0-9\-._~!$&amp;'()*+,;=:]+
				)
				\]
			  | (?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}
				   (?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)
			  | (?:[A-Za-z0-9\-._~!$&amp;'()*+,;=]|%[0-9A-Fa-f]{2})*
			  )
			  (?: : [0-9]* )?
			  (?:/ (?:[A-Za-z0-9\-._~!$&amp;'()*+,;=:@]|%[0-9A-Fa-f]{2})* )*
			| /
			  (?:    (?:[A-Za-z0-9\-._~!$&amp;'()*+,;=:@]|%[0-9A-Fa-f]{2})+
				(?:/ (?:[A-Za-z0-9\-._~!$&amp;'()*+,;=:@]|%[0-9A-Fa-f]{2})* )*
			  )?
			|        (?:[A-Za-z0-9\-._~!$&amp;'()*+,;=:@]|%[0-9A-Fa-f]{2})+
				(?:/ (?:[A-Za-z0-9\-._~!$&amp;'()*+,;=:@]|%[0-9A-Fa-f]{2})* )*
			|
			)
			(?:\? (?:[A-Za-z0-9\-._~!$&amp;'()*+,;=:@/?]|%[0-9A-Fa-f]{2})* )?
			(?:# (?:[A-Za-z0-9\-._~!$&amp;'()*+,;=:@/?]|%[0-9A-Fa-f]{2})* )?
			$
		</xsl:variable>
		<xsl:sequence select="matches($uri, $uri-regex, 'x')"/>
	</xsl:function>
	
	<xsl:template match="uri">
		<xsl:copy>
			<xsl:attribute name="is-uri" select="uri:is-uri(.)"/>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="*">
		<xsl:copy>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>

</xsl:stylesheet>
