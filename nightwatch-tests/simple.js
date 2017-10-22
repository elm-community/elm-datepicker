const url = "http://localhost:8000/examples/simple-nightwatch/index.html";
const textInputSelector = ".elm-datepicker--input";
const topLeftDaySelector = ".elm-datepicker--row:first-child .elm-datepicker--day:first-child";

module.exports = {

  'When selecting a date with the mouse, it should appear in the text input' : function (client) {
    client.url(url);
    client.expect.element(textInputSelector).to.be.present.before(1000);
    client.click(textInputSelector);
    client.expect.element(topLeftDaySelector).to.be.present.before(1000);
    client.click(topLeftDaySelector);
    client.expect.element(textInputSelector).value.to.equal("1969/06/29").before(1000);
    client.end();
  },

  'When entering text, and then selecting a date with the mouse, the selected date should appear in the text input' : function (client) {
    client.url(url);
    client.expect.element(textInputSelector).to.be.present.before(1000);
    client.setValue(textInputSelector, "1 Jan 1980");
    client.expect.element(topLeftDaySelector).to.be.present.before(1000);
    client.click(topLeftDaySelector);
    client.expect.element(textInputSelector).value.to.equal("1969/06/29").before(1000);
    client.end();
  },


  // This test is disabled using !function. Remove to "!" to run it.
  'Characters should not be dropped when entering text quickly' : !function (client) {

    const longTextExample = "The quick brown fox jumped over the lazy dog";

    client.url(url);
    client.expect.element(textInputSelector).to.be.present.before(1000);
    client.setValue(textInputSelector, longTextExample);
    client.expect.element(topLeftDaySelector).to.be.present.before(1000);
    client.expect.element(textInputSelector).value.to.equal(longTextExample);
    client.end();
  },

};
