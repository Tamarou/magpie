<?xml version="1.0"?>
<application>
	<assets>
		<container name="MyContainer">
			<service name="somevar">some value</service>
		</container>
	</assets>
    <pipeline>
    	<match type="regexp" rule="^/basic">
			<add class="Magpie::Pipeline::Moe"/>
			<add class="Magpie::Pipeline::Breadboard::ConfigAssets"/>
			<add class="Magpie::Pipeline::CurlyArgs">
				<parameters>
					<simple_argument>RIGHT</simple_argument>
				</parameters>
			</add>
			<add class="Magpie::Pipeline::Larry"/>
        </match>
    </pipeline>
</application>

