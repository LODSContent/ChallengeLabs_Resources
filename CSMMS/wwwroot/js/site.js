// Please see documentation at https://docs.microsoft.com/aspnet/core/client-side/bundling-and-minification
// for details on configuring this project to bundle and minify static web assets.

// Write your JavaScript code.

$(document).ready(function () {
    $('#generate').click(generateMessages);
    $('#retrieve').click(retrieveMessages);
    $('#checkTable').click(checkTable);
    $('#generateActivity').click(generateActivity);
    $('#checkNotices').click(checkNotices);
    $('#testKeyVault').click(testKeyVault);

    var batchIds = [];


    function generateMessages() {
        var messages = [];
        var batchDate = new Date();
        batchId = "" + batchDate.getFullYear() + "-" + batchDate.getMonth() + "-" + batchDate.getDate() + "T" + batchDate.getHours() + ":" + batchDate.getMinutes() + ":" + batchDate.getSeconds() + "." + batchDate.getMilliseconds();
        batchIds.push(batchId);
        for (var i = 0; i < 5; i++) {
            messages.push({
                BatchId: batchId,
                ID: i,
                Payload: "Message # " + i + " for batch " + batchId
            });
        }
        var data = JSON.stringify({ "Items": messages });
        $.ajax(
            {
                url: "/api/mms/generateQueueMessages",
                method: "POST",
                data: data,
                //dataType: "application/json",
                contentType: "application/json"

            })
            .done(function (resultData) { displayResult(resultData, "Generate Messages"); })
            .fail(function (xhr, status, error) { displayError(error, "Generate Messages"); });
        return false;
    }

    function retrieveMessages() {
        $.get("/api/mms/getQueueMessages").done(function (resultData) {
            displayResult(resultData, "Retrieve Messages");
        }).fail(function (xhr, status, error) {
            displayError(error, "Retrieve Messages");
        });
        return false;
    }

    function checkTable() {
        if (batchIds.length > 0) {
            var success = false;
            for (var lcv = 0; lcv < batchIds.length; lcv++) {
                var batchId = batchIds[lcv];
                $.get(
                    {
                        url: "/api/mms/getTableRows?batchId=" + batchId,
                        async: false
                    }).done(function (resultData) {
                        if (resultData.code > 0) {
                            displayResult(resultData, "Table rows for batch id " + batchId);
                            success = true;
                        }
                    });
                if (success) {
                    batchIds = [];
                    break;
                }
            }
            if (!success) {
                var result = "<h2>Checking table</h2><hr />";
                result += "<p>Processed at " + Date() + "</p>";
                result += "<p>There are no results for the current batch ids.  The web job may not have processed.  Try again in 30 seconds.";
                $('#result').html(result);

            }
        } else {
            result = "<h2>Checking table</h2><hr />";
            result += "<p>Processed at " + Date() + "</p>";
            result += "<p>There are no batch ids.  Try generating messages first.";
            $('#result').html(result);
        }
        return false;

    }

    function generateActivity() {
         var loops = 150;
       $("#result").html("<h2>Generate Activity</h2><p>The system will generate " + loops + " calls to the server and display the results below.</p><ul id='executionResult' class='resultsDetails'></ul><div id='callbacks'></div>");
        var errorCount = 0;
        var callbackCount = 0;
        for (var lcv = 0; lcv < loops; lcv++) {
            $.get("/api/mms/generateActivity/" + lcv).done(function (resultData) {
                $('#executionResult').append("<li>" + resultData.data[0] + "</li>");
                showCallback(++callbackCount, loops);
            }).fail(function (xhr, status, error) {
                $('#executionResult').append("<li>Generated error.  This is expected.  Error count = " + ++errorCount + "</li>");
                showCallback(++callbackCount,loops);
            });
        }
        return false;

        

    }

    function checkNotices() {
        $('#result').html("<h2>Check Alert Notifications</h2><div id='output'></div>");
        $.getJSON("/api/mms/getNotices").done(function (data) {
            if (data.success) {
                if (data.code === 0) {
                    $('#output').html("<h3>There are no alert notifications. </h3>");

                } else {
                    var html = "<p>Here are the notifications:</p><ul class='resultsDetails'>";
                    $(data.data).each(function (index, row) {
                        html += "<li>" + row + "</li>";
                    });
                    html += "</ul>";
                    $('#output').html(html);

                }
            } else {
                $('#output').html("<h3>An error occurred.</h3><p>" + data.data[0] + "</p>");

            }
        }).fail(function (xhr,status,error) {
            $('#output').html("<h3>An error occurred.</h3><p>" + error + "</p>");
        });
    }

    function testKeyVault() {
        $('#result').html("<h2>Test Key vault</h2><div id='output'>,/div>");
        $.getJSON("/api/mms/testKeyVault").done(function (data) {
            if (data.success) {
                     var html = "<p>Key vault is successfully implemented.</p><ul class='resultsDetails'>";
                    $(data.data).each(function (index, row) {
                        html += "<li>" + row + "</li>";
                    });
                    html += "</ul>";
                    $('#output').html(html);

            } else {
                $('#output').html("<h3>An error occurred.</h3><p>" + data.data[0] + "</p>");

            }
        }).fail(function (xhr, status, error) {
            $('#output').html("<h3>An error occurred.</h3><p>" + error + "</p>");
        });
    }

    function showCallback(count, executions) {
        $('#callbacks').text("Execution " + count + " of " + executions);
    }
    function displayResult(data, title) {
        var result = "<h2>" + title + "</h2><hr />";
        result += "<p>Processed at " + Date() + "</p>";
        result += "<table class='table'><thead class='thead-light'><th scope='col'>Result</th><th scope='col'>Value</th></thead><tbody>";
        result += "<tr><th scope='row'>Status</th><td>" + (data.success ? "Success" : "Error") + "<td><tr>";
        result += "<tr><th scope='row'>Code/Count</th><td>" + data.code + "<td><tr>";
        result += "<tr><th scope='row'>Results<th><td><ul class='resultsDetails'>";
        $(data.data).each(function (index, row) {
            result += "<li>" + row + "</li>";
        });
        result += "</ul></tr></tbody></table>";
        $('#result').html(result);

    }

 

    function displayError(error, title) {
        var result = "<h2>" + title + "</h2><hr />";
        result += "<p>Processed at " + Date() + "</p>";
        result += "<p>" + error + "</p>";
        $('#result').html(result);


    }



});
