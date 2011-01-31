//(function () {

  var dirty = true;

  var form = jQuery("#content form"),
    preview = jQuery("#preview"),
    h1 = preview.find("h1 a"),
    date = preview.find(".date"),
    content = preview.find(".content");

  function val(id) {
    return form.find("#input_" + id).val();
  }

  function update() {
    if (dirty) dirty = false; else return;
    h1.text(val("title"));
    h1.attr("href", val("url"));
    date.text(val("time"));
    content.html(val("body"));
    update_markdown();
    update_generated();
  }

  function update_markdown() {
    var sd = new Showdown.converter();
    jQuery("#preview .content").html(
        sd.makeHtml(val("body")));
  }

  function filename() {
    var date = new Date(val("time"));

    return [
      date.getFullYear(),
      date.getMonth() + 1,
      date.getDate(),
      val("title").toLowerCase().replace(/\W+/g, "-")
    ].join("-") + ".txt";
  }

  function update_generated() {
    jQuery("#input_generated").text(
      filename() + '\n\n' +
      "---\n" +
      "title: \"" + val("title") + "\"\n" +
      "time: " + val("time") + "\n" +
      (is_link() ? "url: " + val("url") + "\n" : "") +
      "tags: " + val("tags") + "\n" +
      "\n" +
      val("body"));
  }

  function is_link() {
    return jQuery("#type_link").attr("checked");
  }

  function timezone(date) {
    var o = date.getTimezoneOffset() * -1;
    if (o === 0) return "GMT";
    return sprintf("%+02d:%02d", Math.floor(o / 60), o % 60);
  }

  jQuery("#content form").bind("click keyup", function () {
    dirty = true;
  });

  jQuery(".time a").click(function (event) {
    event.preventDefault();
    var d = new Date();
    jQuery(".time input").val(sprintf(
      "%d-%02d-%02d %02d:%02d:%02d %s",
      d.getFullYear(), d.getMonth() + 1, d.getDate(),
      d.getHours(), d.getMinutes(), d.getSeconds(), timezone(d)));
  }).click();

  jQuery("fieldset.type input:radio").click(function (event) {
    jQuery("#write .url").toggle(is_link());
  });

  setInterval(update, 500);

//}());
