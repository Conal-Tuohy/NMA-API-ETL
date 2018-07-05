<p:declare-step 
	name="initialize-tomcat"
	version="1.0" 
	xmlns:p="http://www.w3.org/ns/xproc" 
>
	<!-- generate a new tomcat-users.xml file with an "admin" user with the "manager-script" role, and a random password -->
	<p:template>
		<p:with-param name="random-password" select="p:system-property('p:episode')"/>
		<p:input port="source"><p:empty/></p:input>
		<p:input port="template">
			<p:inline>
<!-- automatically generated by /usr/local/NMA-API-ETL/install/config/tomcat/initialize-tomcat.xpl -->
<tomcat-users 
	xmlns="http://tomcat.apache.org/xml"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://tomcat.apache.org/xml tomcat-users.xsd"
	version="1.0">
	<role rolename="manager-script"/>
	<user username="admin" password="{$random-password}" roles="manager-script"/>
</tomcat-users>
			</p:inline>
		</p:input>
	</p:template>
	<p:store href="/var/lib/tomcat8/conf/tomcat-users.xml"/>
</p:declare-step>