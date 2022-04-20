library ani_app.globals;


// HTTP
String baseUrl = "https://goload.pro";
String decryptionUrl = "https://goload.pro/encrypt-ajax.php";
String userAgent = "Mozilla/5.0 (X11; Ubuntu; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2919.83 Safari/537.36";


// HTML selectors
String secondKeyPath = "div[class*='videocontent-']";
String keyPath = "body[class^='container-']";
String ivPath = "div[class*='container-']";
String newSecretValuePath = "body[class*='container-']";
String secretValuePath = 'script[data-name="episode"]';

List<String> settings = [
  "",
  "History",
  "Favourites"
];