library ani_app.globals;


// HTTP
const baseUrl = "https://goload.pro";
const decryptionUrl = "https://goload.pro/encrypt-ajax.php";
const userAgent = "Mozilla/5.0 (X11; Ubuntu; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2919.83 Safari/537.36";


// Regex
final titleRegex = RegExp(r'\b-episode-\d+|-dub-\d+|-ova-\d+');

const localStorage = "ani-mobile.json";

// HTML selectors
const secondKeyPath = "div[class*='videocontent-']";
const keyPath = "body[class^='container-']";
const ivPath = "div[class*='container-']";
const newSecretValuePath = "body[class*='container-']";
const secretValuePath = 'script[data-name="episode"]';

const settings = [
  "",
  "History",
  "Favourites"
];