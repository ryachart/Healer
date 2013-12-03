
// Use Parse.Cloud.define to define as many cloud functions as you want.
// For example:

var max_stamina = 3;
var stamina_tick_time = 28800;

Parse.Cloud.define("checkDAU", function(request, response) {
    var query = new Parse.Query("player");
    var now = (new Date()).getTime() / 1000;
    var midnightToday = new Date((now - now % 86400) * 1000);
    console.log("Now : " + now + "\nMidnight Today: " + midnightToday);
    query.greaterThanOrEqualTo("updatedAt", midnightToday);
    query.count({ 
        success : function(number) {
            response.success(number);
        }, error : function() {
            response.error("Failed to calculate daily installs");
        }
        });
});

Parse.Cloud.define("checkPurchases", function(request, response){
    var query = new Parse.Query("purchase");
    var now = (new Date()).getTime() / 1000;
    var midnightToday = new Date((now - now % 86400) * 1000);
    console.log("Now : " + now + "\nMidnight Today: " + midnightToday);
    query.greaterThanOrEqualTo("createdAt", midnightToday);
    query.count({ 
        success : function(number) {
            response.success(number);
        }, error : function() {
            response.error("Failed to calculate daily purchases");
        }
        });
});

Parse.Cloud.define("checkInstalls", function(request, response){
    var query = new Parse.Query("player");
    var now = (new Date()).getTime() / 1000;
    var midnightToday = new Date((now - now % 86400) * 1000);
    console.log("Now : " + now + "\nMidnight Today: " + midnightToday);
    query.greaterThanOrEqualTo("createdAt", midnightToday);
    query.count({ 
        success : function(number) {
            response.success(number);
        }, error : function() {
            response.error("Failed to calculate DAU");
        }
        });
    
});

function seconds_between_dates(dateA, dateB) {
    var dif = dateA.getTime() - dateB.getTime()
    return dif / 1000;
}

function check_stamina_owed(tick_time, last_tick) {
    var today = new Date();
    var diff = seconds_between_dates(today, last_tick);
    if (diff > tick_time) {
        var total_owed = diff / tick_time;
        return Math.floor(total_owed);
    }
    return 0;
}

Parse.Cloud.define("getStamina", function(request, response) {
    var query = new Parse.Query("stamina");
    query.equalTo("playerId", request.params.playerId);
    query.find({ 
        success : function(results) {
            var object = null;
            var staminaResult = 0;
            if (results.length > 0) {
                object = results[0];
                var last_tick = object.get("last_tick_time");
                if (!last_tick) {
                    last_tick = new Date();
                    object.set("last_tick_time", last_tick);
                }
                var stamina_owed = check_stamina_owed(stamina_tick_time, last_tick);
                if (stamina_owed > 0) {
                    var dangling_time = seconds_between_dates(new Date(),last_tick) * 1000;
                    dangling_time -= Math.min(max_stamina, stamina_owed) * stamina_tick_time * 1000;
                    var new_time = new Date().getTime() - dangling_time;
                    last_tick = new Date(new_time);
                    object.set("stamina", Math.min(max_stamina, object.get("stamina") + stamina_owed));
                    object.set("last_tick_time", last_tick);
                    object.save();
                }
                staminaResult = object.get("stamina");
            } else {
                object = new Parse.Object("stamina");
                object.set("playerId", request.params.playerId);
                object.set("stamina", max_stamina);
                object.set("last_tick_time", new Date());
                object.save();
                staminaResult = object.get("stamina");
            }
            var last_tick = object.get("last_tick_time");
            var now = new Date();
            var dif = (last_tick.getTime() / 1000 + stamina_tick_time) - now.getTime() / 1000;
            var secondsUntil = dif;
            response.success({"stamina" : staminaResult, "secondsUntilNextStamina" : secondsUntil, "maxStamina" :  max_stamina, "secondsPerStamina" : stamina_tick_time});
        }, error : function() {
            //If we didn't find one, create one
            response.error("Failed to perform getStamina");
        }
        });
});

Parse.Cloud.define("spendStamina", function(request, response) {
    var query = new Parse.Query("stamina");
    query.equalTo("playerId", request.params.playerId);
    query.find({ 
        success : function(results) {
            var object = null;
            var staminaResult = 0;
            if (results.length > 0) {
                object = results[0]; 
                var currentStamina = object.get("stamina");
                if (currentStamina > 0) {    
                    if (currentStamina == max_stamina) {
                        object.set("last_tick_time", new Date());
                    }       
                    object.set("stamina", currentStamina - 1);
                    object.save();
                    staminaResult = object.get("stamina");
                    var last_tick = object.get("last_tick_time");
                    var now = new Date();
                    var dif = (last_tick.getTime() / 1000 + stamina_tick_time) - now.getTime() / 1000;
                    var secondsUntil = dif;
                    response.success({"stamina" : staminaResult, "success" : true, "secondsPerStamina" : stamina_tick_time, "secondsUntilNextStamina" : secondsUntil});
                } else {
                    response.error("Couldn't spend stamina.  No stamina to spend");
                }
            } else {
                response.error("This player has no stamina object");
            }
        }, error : function() {
            //If we didn't find one, create one
            response.error("Failed to perform spendStamina");
        }
        });
});

Parse.Cloud.afterSave("player", function(request) {
    var query = new Parse.Query("tier1progress")
    query.equalTo("playerId", request.object.id);
    query.find({
        success : function(results) {
            var object;
            if (results.length > 0) {
                object = results[0];
            } else {
                object = new Parse.Object("tier1progress");
                object.set("playerId", request.object.id);
            }
            var levelScores = request.object.get("levelScores");
            var levelRatings = request.object.get("levelRatings");
            for (var i = 1; i < 22; ++i) {
                if (levelScores.length > i) {
                    object.set("boss_score_"+(1+i), levelScores[i]);
                } else {
                    break;
                }
                if (levelRatings.length > i) {
                    object.set("boss_rating_"+(1+i), levelRatings[i]);
                } else {
                    break;
                }
            }
            object.save({
                success : function(res) {
                }, error : function(res, error) {
                }
            });
        },
        error : function () {
            
        }
    });
});