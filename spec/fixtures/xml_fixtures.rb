# frozen_string_literal: true

##
# Quick and easy XML fixtures
module XmlFixtures
  def workflow_template
    WorkflowTemplateLoader.load_as_xml('accessionWF', 'dor')
    # Nokogiri::XML(
    # <<-XML
    # <workflow-def id="accessionWF">
    #   <process name="start-accession" status="completed" attempts="1" lifecycle="submitted" laneId="default"/>
    #   <process name="descriptive-metadata" status="waiting" lifecycle="described" laneId="default"/>
    #   <process name="rights-metadata" status="waiting" laneId="default"/>
    #   <process name="content-metadata" status="waiting" laneId="default"/>
    #   <process name="technical-metadata" status="waiting" laneId="default"/>
    #   <process name="remediate-object" status="waiting" laneId="default"/>
    #   <process name="shelve" status="waiting" laneId="default"/>
    #   <process name="publish" status="waiting" lifecycle="published" laneId="default"/>
    #   <process name="provenance-metadata" status="waiting" laneId="default"/>
    #   <process name="sdr-ingest-transfer" status="waiting" laneId="default"/>
    #   <process name="sdr-ingest-received" status="waiting" lifecycle="deposited" laneId="default"/>
    #   <process name="reset-workspace" status="waiting" laneId="default"/>
    #   <process name="end-accession" status="waiting" lifecycle="accessioned" laneId="default"/>
    # </workflow-def>
    # XML
    # )
  end

  def initial_workflow
    WorkflowTransformer.initial_workflow(workflow_template)
  end
end
