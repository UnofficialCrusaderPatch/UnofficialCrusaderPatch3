
const receiveBooleanOrFallback = function (bool, fallback = false) {
    return typeof bool === "boolean" ? bool : fallback;
}

const receiveStringOrFallback = function (str, fallback = "") {
    return typeof str === "string" ? str : fallback;
}

class AiControl {
    binks;
    speech;
    lines;
    portrait;
    aic;
    aiv;
    lord;
    startTroops;

    static fromControlObject(controlObj) {
        const aiControl = new AiControl();
        aiControl.binks = receiveBooleanOrFallback(controlObj.binks);
        aiControl.speech = receiveBooleanOrFallback(controlObj.speech);
        aiControl.lines = receiveBooleanOrFallback(controlObj.lines);
        aiControl.portrait = receiveBooleanOrFallback(controlObj.portrait);
        aiControl.aic = receiveBooleanOrFallback(controlObj.aic);
        aiControl.aiv = receiveBooleanOrFallback(controlObj.aiv);
        aiControl.lord = receiveBooleanOrFallback(controlObj.lord);
        aiControl.startTroops = receiveBooleanOrFallback(controlObj.startTroops);
        return aiControl;
    }

    clone() {
        const aiControl = new AiControl();
        aiControl.binks = this.binks;
        aiControl.speech = this.speech;
        aiControl.lines = this.lines;
        aiControl.portrait = this.portrait;
        aiControl.aic = this.aic;
        aiControl.aiv = this.aiv;
        aiControl.lord = this.lord;
        aiControl.startTroops = this.startTroops;
        return aiControl;
    }

    toControlObject() {
        return {
            binks: this.binks,
            speech: this.speech,
            lines: this.lines,
            portrait: this.portrait,
            aic: this.aic,
            aiv: this.aiv,
            lord: this.lord,
            startTroops: this.startTroops,
        };
    }
}

class AiMeta {
    name;
    description;
    author;
    link;
    version;
    defaultLang;
    supportedLang;
    possibleSettings;
    root;

    static fromMetaRootPath(path) {
        const metaPath = `${aiSetting.root}/meta.json`; // TODO
        // for paths
        // TODO: load meta file an verify

        const aiMeta = new AiMeta();
        aiMeta.name = receiveStringOrFallback(metaObj.name);
        aiMeta.description = receiveStringOrFallback(metaObj.description);
        aiMeta.author = receiveStringOrFallback(metaObj.author);
        aiMeta.link = receiveStringOrFallback(metaObj.link);
        aiMeta.version = receiveStringOrFallback(metaObj.version);
        aiMeta.defaultLang = receiveStringOrFallback(metaObj.defaultLang, null);
        aiMeta.supportedLang = Array.isArray(metaObj.supportedLang) ? metaObj.supportedLang : [];
        aiMeta.possibleSettings = new AiControl(metaObj.possibleSettings ?? {});

        // TODO
        aiMeta.root = metaPath;

        return aiMeta;
    }
}

class AiSetting {
    name;
    language;
    root;
    control;
    aiMeta;

    // if received from a present config
    static fromSettingObject(name, settingObj) {
        const aiSetting = new AiSetting();

        aiSetting.root = receiveStringOrFallback(settingObj.root);
        if (!aiSetting.root) {
            return null; // does not exist
        }

        aiSetting.aiMeta = AiMeta.fromMetaPath(aiSetting.root);
        if (!aiSetting.aiMeta) {
            return null; // does not exist
        }

        aiSetting.name = receiveStringOrFallback(name);
        aiSetting.language = receiveStringOrFallback(settingObj.language, null);
        aiSetting.control = new AiControl(settingObj.control ?? {});

        // updating state based on meta, in case invalid settings are present
        if (aiSetting.name !== aiSetting.aiMeta.name) {
            aiSetting.name = aiSetting.aiMeta.name;
        }

        if (aiSetting.language !== null && !aiSetting.aiMeta.supportedLang.includes(aiSetting.language)) {
            aiSetting.language = aiSetting.aiMeta.defaultLang;
        }

        return aiSetting;
    }

    static fromMeta(meta) {
        const aiSetting = new AiSetting();
        aiSetting.name = meta.name;
        aiSetting.root = meta.root;
        aiSetting.language = meta.defaultLang;
        aiSetting.control = meta.possibleSettings.clone();
        aiSetting.aiMeta = meta;
        return aiSetting;
    }

    toSettingNameAndObject() {
        const settingObj = {
            language: this.language,
            root: this.root,
            control: this.control.toControlObject(),
        };
        return [this.name, settingObj];
    }
}

const AI_SLOTS = ["rat", "snake", "pig", "wolf", "saladin", "caliph", "sultan", "lionheart", "frederick", "phillip", "wazir", "emir", "nizar", "sheriff", "marshal", "abbot"];

const AI_SETTINGS = new Map(AI_SLOTS.map((ai) => [ai, []]));

function initMainElements() {
    const OVERVIEW = document.querySelector(".ai-swapper__overview");
    const CHANGE_MENU = document.querySelector(".ai-swapper__change-menu");

    // general init change menu
    CHANGE_MENU.querySelector(".ai-swapper__change-menu__close").addEventListener("click", () => CHANGE_MENU.close());

    const activateEditDialog = function (event) {
        const slotName = Array.from(event.currentTarget.classList).find((cssClass) => cssClass.startsWith("slot--")).replace("slot--", "").toUpperCase();

        CHANGE_MENU.querySelector(".slot-name").textContent = slotName;
        CHANGE_MENU.showModal();
    }

    const overviewTemp = document.querySelector(".template--ai-overview-slot");
    for (const ai of AI_SLOTS) {
        const clone = overviewTemp.content.cloneNode(true);
        const cloneDiv = clone.querySelector(".ai-swapper__overview__ai");
        cloneDiv.classList.add(`slot--${ai}`);
        clone.querySelector(".slot-name").textContent = ai.toUpperCase();
        // TODO: picture + current
        cloneDiv.addEventListener("click", activateEditDialog);

        OVERVIEW.appendChild(clone);
    }

    const createResultConfig = function () {
        const configState = {};
        for (const [ai, settings] of AI_SETTINGS) {
            if (!settings.length) {
                continue;
            }

            configState[ai] = {
                contents: {
                    value: {}
                }
            }

            // currently only one ai for override
            // the aiSwapper lacks real override support currently anyway, since the original thought
            // during module creation were no overlaps in the "true" settings of the used ais
            const [name, setting] = settings[0].toSettingNameAndObject();
            configState[ai].contents.value[name] = setting;
        }
        return configState;
    }
}

/** INIT **/

addEventListener(
    DONE_EVENT_NAME,
    async () => {
        // dummy:
        HOST_FUNCTIONS.getCurrentConfig = async () => ({
            "CONTROL+B": "ALT+H",
            "K": "Hi",
        });


        initMainElements();
        // SANDBOX_FUNCTIONS.getConfig = () => Object.fromEntries(CURRENT_KEY_COMBINATIONS.entries());
    },
    { once: true }
);

// allows to find file for debugging
//# sourceURL=ai-swapper.js