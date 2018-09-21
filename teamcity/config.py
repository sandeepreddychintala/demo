# Teamcity configurations
SERVER_PROTCOL = "http"  # XXXXXX
SERVER_HOST = "localhost"  # XXXXXX
SERVER_PORT = 9090  # XXXXXX
SERVER_USER = "Sandeep Chintala"  # XXXXXX
SERVER_PASSWORD = "Sriniv@s13"  # XXXXXX

SERVER_URL = "{0}://{1}:{2}".format(SERVER_PROTCOL, SERVER_HOST, SERVER_PORT)

PROCESSED_LOG = "processed.log"
LAST_PROCESSED_TIMESTAMP_LOG = "last_processed_timestamp.log" # XXXXXX
SUB_DIR_OF = "tests"  # XXXXXX

COPY_BUILDTYPE_XML = "copybuildtype.xml"
TRIGGER_BUILD_XML = "triggerbuild.xml"
PROJECT_ID = "XmlImport"  # XXXXXX
SOURCE_ATTRIBUTE = "sourceBuildTypeLocator"
TARGET_ATTRIBUTE = "name"
SOURCE_BUILD_TYPE_ID = "XmlImport_Builder"  # XXXXXX

TRIGGER_BUILDTYPE_ATTRIBUTE = "buildType"
SOURCE_TRIGGER_BUILD_ATTRIBUTE = "id"
TARGET_TRIGGER_BUILD_ATTRIBUTE = "id"

# Project configuration in xml
XML_PROJECT_CONFIG_FILE = "project_config.xml"  # XXXXXX give your xml file configuration
