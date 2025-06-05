// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"
import * as bootstrap from "bootstrap"
import "./packs/gantt_chart"

// $(".nav-link").on("click", function(){
//     console.log("clicked");
//     console.log(this);
//     // $(".nav-link").find(".active").removeClass("active");
//     // $(this).addClass("active");
//  });

document.addEventListener('turbo:load', function() {
    // const elements = document.getElementsByClassName("nav-link")

    // for (let i = 0; i < elements.length; i++) {
    //     elements[i].addEventListener("click", navButtonClick);
    // };

    // function navButtonClick(event) {
    //     console.log("clicked");
    //     console.log(event.target);
    //     // const t2 = document.getElementById("t2");
    //     // const isNodeThree = t2.firstChild.nodeValue === "three";
    //     // t2.firstChild.nodeValue = isNodeThree ? "two" : "three";
    // }
});