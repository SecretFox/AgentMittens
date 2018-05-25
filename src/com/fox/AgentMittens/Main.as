import com.GameInterface.AgentSystemAgent;
import com.GameInterface.DistributedValue;
import mx.utils.Delegate;

class com.fox.AgentMittens.Main {
	private var AgentWindow:DistributedValue;
	static var Mittens:Object;
	private var XMLFile:XML;

	public static function main(swfRoot:MovieClip):Void {
		var s_app:Main = new Main(swfRoot);
		swfRoot.onLoad = function() {s_app.Load()};
		swfRoot.onUnload = function() {s_app.Unload()};
	}

	public function Main() {
		Mittens = new Object();
		XMLFile = new XML();
		XMLFile.ignoreWhite = true;
		XMLFile.onLoad = Delegate.create(this, ProcessXML);
		AgentWindow = DistributedValue.Create("agentSystem_window");
		XMLFile.load("AgentMittens/AgentConfig.xml");
	}
	public function Load() {
		AgentWindow.SignalChanged.Connect(Hook, this);
	}
	public function Unload() {
		AgentWindow.SignalChanged.Disconnect(Hook, this);
	}
	private function ProcessXML(success:Boolean) {
		if (success) {
			var root:XMLNode = XMLFile.childNodes[0];
			var AgentData:Object = new Object();
			for (var i:Number = 0; i < root.childNodes.length; i++ ) {
				var agentNode = root.childNodes[i];
				Mittens[agentNode.attributes.id] = new Object();
				Mittens[agentNode.attributes.id]["Name"] = agentNode.attributes.name;
				Mittens[agentNode.attributes.id]["Image"] = agentNode.attributes.img;
				Mittens[agentNode.attributes.id]["Species"] = agentNode.attributes.species;
				Mittens[agentNode.attributes.id]["Profession"] = agentNode.attributes.profession;
				Mittens[agentNode.attributes.id]["Replacement"] = agentNode.attributes.descRepl;
			}
		}
		XMLFile = undefined;
	}
	public static function IsMittenAgent(id:Number) {
		return Mittens[string(id)];
	}
	private function Hook() {
		if (AgentWindow.GetValue()) {
			if (_global.GUI.AgentSystem.RosterIcon.prototype.LoadPortrait) {
				if (!_global.GUI.AgentSystem.RosterIcon.prototype._LoadPortrait) {
					_global.GUI.AgentSystem.RosterIcon.prototype._LoadPortrait = _global.GUI.AgentSystem.RosterIcon.prototype.LoadPortrait;
					_global.GUI.AgentSystem.RosterIcon.prototype.LoadPortrait = function ():Void {
						if (Main.Mittens[string(this.data.m_AgentId)]["Image"]) {
							var newPortrait = com.Utils.Format.Printf( "rdb:%.0f:%.0f", _global.Enums.RDBID.e_RDB_Res_AgentPortraits, this.data.m_AgentId);
							if (newPortrait == this.m_PortraitPath) return;
							if (this.m_PortraitLoading) return;
							if (this.m_PortraitClip != undefined)
							{
								this.m_PortraitClip.removeMovieClip();
								this.m_PortraitClip = undefined;
							}
							var path = "AgentMittens\\MittenRoster\\" + Main.Mittens[string(this.data.m_AgentId)]["Image"] + ".png";
							this.m_PortraitClip = this.m_Frame.m_Portrait.createEmptyMovieClip("m_PortraitClip", this.m_Frame.m_Portrait.getNextHighestDepth());
							this.m_PortraitLoading = true;
							this.m_PortraitPath = newPortrait;
							this.m_PortraitLoader.loadClip(path, this.m_PortraitClip);
						} else{
							this._LoadPortrait();
						}
					}
					//First run, change the icons that were loaded before LoadPortrait was hooked
					for (var i in _root.agentsystem.m_Window.m_Content.m_Roster) {
						var agentIcon:MovieClip = _root.agentsystem.m_Window.m_Content.m_Roster[i];
						if (IsMittenAgent(agentIcon.data.m_AgentId)) {
							agentIcon.m_PortraitLoading = false;
							agentIcon.m_PortraitPath = "";
							agentIcon["LoadPortrait"]();
							if(Main.Mittens[string(agentIcon.data.m_AgentId)]["Name"]) agentIcon.m_Name.text = Mittens[string(agentIcon.data.m_AgentId)]["Name"];
						}
					}
				}
				if (!_global.GUI.AgentSystem.RosterIcon.prototype._setData) {
					_global.GUI.AgentSystem.RosterIcon.prototype._setData = _global.GUI.AgentSystem.RosterIcon.prototype.setData;
					_global.GUI.AgentSystem.RosterIcon.prototype.setData = function(data:AgentSystemAgent) {
						this._setData(data);
						if(Main.Mittens[string(this.data.m_AgentId)]["Name"]) this.m_Name.text = Main.Mittens[string(this.data.m_AgentId)]["Name"]
					}
				}
				if (!_global.GUI.AgentSystem.MissionReward.prototype._AssignAgent) {
					_global.GUI.AgentSystem.MissionReward.prototype._AssignAgent = _global.GUI.AgentSystem.MissionReward.prototype.AssignAgent;
					_global.GUI.AgentSystem.MissionReward.prototype.AssignAgent = function(agent:AgentSystemAgent) {
						this._AssignAgent(agent)
						if(Main.Mittens[string(agent.m_AgentId)]["Name"]) this.m_AgentName.text = Main.Mittens[string(agent.m_AgentId)]["Name"];
					}
				}
				if (!_global.GUI.AgentSystem.MissionDetail.prototype._UpdateAgentDisplay) {
					_global.GUI.AgentSystem.MissionDetail.prototype._UpdateAgentDisplay = _global.GUI.AgentSystem.MissionDetail.prototype.UpdateAgentDisplay;
					_global.GUI.AgentSystem.MissionDetail.prototype.UpdateAgentDisplay = function() {
						this._UpdateAgentDisplay();
						if (Main.Mittens[string(this.m_AgentData.m_AgentId)]["Name"]) this.m_AgentName.text = Main.Mittens[string(this.m_AgentData.m_AgentId)]["Name"];
					}
				}
				if (!_global.GUI.AgentSystem.AgentInfo.prototype._SetData) {
					_global.GUI.AgentSystem.AgentInfo.prototype._SetData = _global.GUI.AgentSystem.AgentInfo.prototype.SetData;
					_global.GUI.AgentSystem.AgentInfo.prototype.SetData = function(agentData:AgentSystemAgent) {
						this._SetData(agentData);
						if (Main.IsMittenAgent(agentData.m_AgentId)) {
							var AgentObject:Object = Main.Mittens[string(agentData.m_AgentId)];
							if (AgentObject["Replace"] && AgentObject["Name"]) {
								this.m_Description.htmlText = this.m_Description.htmlText.split(AgentObject["Replace"]).join(AgentObject["Name"]);
							};
							if (AgentObject["Species"]) {
								this.m_Species.m_Right.text = AgentObject["Species"];
							};
							if (AgentObject["Name"]) {
								this.m_Name.text = AgentObject["Name"];
							};
							if (AgentObject["Profession"]) {
								this.m_Species.m_Right.text = AgentObject["Profession"];
							};
						}
					}
				}
			} else {
				setTimeout(Delegate.create(this, Hook), 50);
			}
		}
	}

}