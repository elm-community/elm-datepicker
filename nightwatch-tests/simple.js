const url = "http://localhost:8000/examples/simple-nightwatch/index.html";
const textInputSelector = ".elm-datepicker--input";
const topLeftDaySelector = ".elm-datepicker--row:first-child .elm-datepicker--day:first-child";


const defaultWait = 1000;

module.exports = {

  'When selecting a date with the mouse, it should appear in the text input' : function (client) {
    client.url(url);
    client.expect.element(textInputSelector).to.be.present.before(defaultWait);
    client.click(textInputSelector);
    client.expect.element(topLeftDaySelector).to.be.present.before(defaultWait);
    client.click(topLeftDaySelector);
    client.expect.element(textInputSelector).value.to.equal("1969/06/29").before(defaultWait);
    client.end();
  },

  'When entering text, and then selecting a date with the mouse, the selected date should appear in the text input' : function (client) {
    client.url(url);
    client.expect.element(textInputSelector).to.be.present.before(defaultWait);
    client.click(textInputSelector);
    slowlySendKeys(client, textInputSelector, "1 Jan 1980");
    client.expect.element(topLeftDaySelector).to.be.present.before(defaultWait);
    client.click(topLeftDaySelector);
    client.expect.element(textInputSelector).value.to.equal("1969/06/29").before(defaultWait);
    client.end();
  },

  'When entering the text of a valid date, then pressing the ENTER key, the entered date should appear in the date picker' : function (client) {
    client.url(url);
    client.expect.element(textInputSelector).to.be.present.before(defaultWait);
    client.click(textInputSelector);
    slowlySendKeys(client, textInputSelector, "1 Jan 1980");
    client.sendKeys(textInputSelector, client.Keys.ENTER);
    client.expect.element(topLeftDaySelector).to.be.present.before(defaultWait);
    client.expect.element(".elm-datepicker--row:first-child .elm-datepicker--day:nth-child(3)")
      .to.have.attribute('class').which.contains('elm-datepicker--picked');
    client.expect.element("h1").text.to.equal("Jan 1, 1980");

    // now we click on another value, to make sure the input is updated
    client.click(topLeftDaySelector);
    client.expect.element(textInputSelector).value.to.equal("1979/12/30").before(defaultWait);
    client.expect.element("h1").text.to.equal("Dec 30, 1979");
    client.end();
  },

  // This test has been commented out, we are currently unable to find a
  // satisfactory solution for https://github.com/elm-community/elm-datepicker/issues/63.
  //
  // 'Characters should not be dropped when entering text quickly' : function (client) {
  //
  //   const longTextExample = "The quick brown fox jumped over the lazy dog";
  //
  //   client.url(url);
  //   client.expect.element(textInputSelector).to.be.present.before(defaultWait);
  //   client.click(textInputSelector);
  //   client.sendKeys(textInputSelector, longTextExample);
  //   client.expect.element(textInputSelector).value.to.equal(longTextExample).before(defaultWait);
  //   client.end();
  // },

  'Manually entered text should not be cleared when the view re-renders' : function (client) {

    client.url(url);
    client.expect.element(textInputSelector).to.be.present.before(defaultWait);
    client.click(textInputSelector);
    slowlySendKeys(client, textInputSelector, "testing");

    // the SimpleNightwatch.elm app has a NoOp message that is triggered after 2
    // seconds. The NoOp causes a re-render of the app. This should not
    // clear the manually entered text.
    client.pause(3000);
    client.expect.element(textInputSelector).value.to.equal("testing").before(defaultWait);
    client.end();
  },


};


function slowlySendKeys(client, selector, text) {
  for (i in text) {
    client.sendKeys(selector, text[i]);
    client.pause(50);
  }
}
