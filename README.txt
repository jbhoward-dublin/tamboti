Notes for Developers - 

Icon stock is from - http://www.famfamfam.com/lab/icons/silk/

JQuery processing framework is found in src/org/exist/xquery/lib

To install:

cd into the tamboti directory and call ant; a file, tamboti-1.0.xar, is created.

log in as admin to eXist, go to the Package Reposistory, choose tamboti-1.0.xar and upload it.

click "Install" and access tamboti at <http://localhost:8080/exist/apps/library/> or <http://localhost:8080/exist/apps/tamboti/>.

Note that in $EXIST_HOME/webapp/WEB-INF/controller-config.xml, the following mappings have to be set

  <root pattern="/apps/library" path="xmldb:exist:///db/tamboti"/>
  <root pattern="/apps/tamboti" path="xmldb:exist:///db/tamboti"/>

before
  
  <root pattern="/apps" path="xmldb:exist:///db"/>
