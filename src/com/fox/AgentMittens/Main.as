import com.GameInterface.AgentSystemAgent;
import com.GameInterface.DistributedValue;
import mx.utils.Delegate;
import com.GameInterface.Tooltip.*;

class com.fox.AgentMittens.Main {
	private var AgentWindow:DistributedValue;
	static var Mittens:Object;
	private var XMLFile:XML;
	static var UpdateDescription:Function;
	private var Loaded:Boolean = false;

	public static function main(swfRoot:MovieClip):Void {
		var s_app = new Main(swfRoot);
		swfRoot.onLoad = function() {s_app.Load()};
		swfRoot.onUnload = function() {s_app.Unload()};
	}

	public function Main() {
		UpdateDescription = Delegate.create(this, LoadConfig);
		Mittens = new Object();
		LoadConfig();
		AgentWindow = DistributedValue.Create("agentSystem_window");

	}
	private function LoadConfig() {
		XMLFile = new XML();
		XMLFile.ignoreWhite = true;
		XMLFile.onLoad = Delegate.create(this, ProcessXML);
		XMLFile.load("AgentMittens/AgentConfig.xml");
	}

	public function Load() {
		AgentWindow.SignalChanged.Connect(Hook, this);
		setTimeout(Delegate.create(this, Hook), 500);
	}
	public function Unload() {
		AgentWindow.SignalChanged.Disconnect(Hook, this);
	}
	private function ProcessXML(success:Boolean) {
		if (success) {
			var root:XMLNode = XMLFile.childNodes[0];
			for (var i in root.childNodes) {
				var agentNode:XMLNode = root.childNodes[i];
				if (agentNode.nodeName == "Agent") {
					//name and img path for roster
					if(!Loaded){
						var id = agentNode.attributes.id;
						for (var y in agentNode.childNodes) {
							var node:XMLNode = agentNode.childNodes[y];
							if (node.nodeName == "bio") {
								if (id) {
									var Agent = Mittens[id] = new Object();
									if (node.attributes.name) Agent["Name"] = node.attributes.name;
									if (node.attributes.img) Agent["Image"] = node.attributes.img;
								}
							}
						}
					}
					// Not stored anywhere, only set when displaying agent sheet
					var infosheet = _root.agentsystem.m_Window.m_Content.m_AgentInfoSheet;
					if (infosheet && agentNode.attributes.id == infosheet.m_AgentData.m_AgentId) {
						for (var y in agentNode.childNodes) {
							var node:XMLNode = agentNode.childNodes[y];
							if (node.nodeName == "desc" && node.firstChild.nodeValue) infosheet.m_Description.htmlText = node.firstChild.nodeValue;
							if (node.nodeName == "traits") {
								if (node.attributes.trait1Title)infosheet.m_Trait1Category.text = node.attributes.trait1Title;
								if (node.attributes.trait1Text) infosheet.m_Trait1.text = node.attributes.trait1Text;
								if (node.attributes.trait1Tooltip) {
									infosheet.m_TraitTooltip1.removeMovieClip();
									var tooltipText = node.attributes.trait1Tooltip;
									TooltipUtils.AddTextTooltip( infosheet.m_TraitTooltip1, tooltipText, 250, TooltipInterface.e_OrientationHorizontal,  true);
								}
								if (node.attributes.trait2Title) infosheet.m_Trait2Category.text = node.attributes.trait2Title;
								if (node.attributes.trait2Text) infosheet.m_Trait2.text = node.attributes.trait2Text;
								if (node.attributes.trait2Tooltip) {
									infosheet.m_TraitTooltip2.removeMovieClip();
									var tooltipText = node.attributes.trait2Tooltip;
									TooltipUtils.AddTextTooltip( infosheet.m_TraitTooltip2, tooltipText, 250, TooltipInterface.e_OrientationHorizontal,  true);
								}
							}
							if (node.nodeName == "bio") {
								if (node.attributes.replace) {
									var replacements = node.attributes.replace.split("#");
									for (var x in replacements){
										var replacement = replacements[x].split("|");
										if (replacement[0] && replacement[1]){
											infosheet.m_Description.htmlText = infosheet.m_Description.htmlText.split(replacement[0]).join(replacement[1]);
										}
									}
								};
								if (node.attributes.species) {
									infosheet.m_Species.m_Right.text = node.attributes.species;
								};
								if (node.attributes.name) {
									infosheet.m_Name.text = node.attributes.name;
								};
								if (node.attributes.profession) {
									infosheet.m_Profession.m_Right.text = node.attributes.profession;
								};
								if (node.attributes.age) {
									infosheet.m_Age.m_Right.text = node.attributes.age;
								};
								if (node.attributes.gender) {
									infosheet.m_Gender.m_Right.text = node.attributes.gender;
								};
							}
							if (node.nodeName == "passives") {
								if (node.attributes.passiveName) infosheet.m_PassiveName.text = node.attributes.passiveName;
								if (node.attributes.passiveAmount1 && node.attributes.passiveText1 && node.attributes.passiveAmount2 && node.attributes.passiveText2) {
									var text25 = '<font size="14"><u><b>Level 25 Passive Ability</b></u>\n';
									var desc25 = "<font color='#ffc600'>" + node.attributes.passiveAmount1 + "</font>" + " " + node.attributes.passiveText1 + "\n\n";
									var text50 = "<u><b>Level 50 Passive Ability</b></u>\n";
									var desc50 = "<font color='#ffc600'>" + node.attributes.passiveAmount2 + "</font>" + " " + node.attributes.passiveText2 + "</font>";
									var finalText = text25 + desc25 + text50 + desc50;
									infosheet.m_PassiveDescription.htmlText = finalText;
								}
							}
						}
					}
				}
			}
			Loaded = true;
		}
		XMLFile = undefined;
	}
	private function Hook() {
		if (!AgentWindow.GetValue()) return;
		if (!_global.GUI.AgentSystem.RosterIcon.prototype.LoadPortrait || !_root.agentsystem.m_Window.m_Content) {
			setTimeout(Delegate.create(this, Hook), 50);
			return
		}
		if (!_global.GUI.AgentSystem.RosterIcon.prototype._LoadPortrait) {
			_global.GUI.AgentSystem.RosterIcon.prototype._LoadPortrait = _global.GUI.AgentSystem.RosterIcon.prototype.LoadPortrait;
			_global.GUI.AgentSystem.RosterIcon.prototype.LoadPortrait = function ():Void {
				if (Main.Mittens[string(this.data.m_AgentId)]["Image"]) {
					var newPortrait = com.Utils.Format.Printf( "rdb:%.0f:%.0f", _global.Enums.RDBID.e_RDB_Res_AgentPortraits, this.data.m_AgentId);
					if (newPortrait == this.m_PortraitPath) return;
					if (this.m_PortraitLoading) return;
					if (this.m_PortraitClip != undefined) {
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
				if (Mittens[string(agentIcon.data.m_AgentId)]) {
					agentIcon.m_PortraitLoading = false;
					agentIcon.m_PortraitPath = "";
					agentIcon["LoadPortrait"]();
					if (Main.Mittens[string(agentIcon.data.m_AgentId)]["Name"]) agentIcon.m_Name.text = Mittens[string(agentIcon.data.m_AgentId)]["Name"];
				}
			}
		}
		if (!_global.GUI.AgentSystem.RosterIcon.prototype._setData) {
			_global.GUI.AgentSystem.RosterIcon.prototype._setData = _global.GUI.AgentSystem.RosterIcon.prototype.setData;
			_global.GUI.AgentSystem.RosterIcon.prototype.setData = function(data:AgentSystemAgent) {
				this._setData(data);
				if (Main.Mittens[string(data.m_AgentId)]["Name"]) this.m_Name.text = Main.Mittens[string(data.m_AgentId)]["Name"]
				}
		}
		if (!_global.GUI.AgentSystem.MissionReward.prototype._AssignAgent) {
			_global.GUI.AgentSystem.MissionReward.prototype._AssignAgent = _global.GUI.AgentSystem.MissionReward.prototype.AssignAgent;
			_global.GUI.AgentSystem.MissionReward.prototype.AssignAgent = function(agent:AgentSystemAgent) {
				this._AssignAgent(agent)
				if (Main.Mittens[string(agent.m_AgentId)]["Name"]) this.m_AgentName.text = Main.Mittens[string(agent.m_AgentId)]["Name"];
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
				if(Main.Mittens[string(agentData.m_AgentId)])Main.UpdateDescription();
			}
		}
	}
}
