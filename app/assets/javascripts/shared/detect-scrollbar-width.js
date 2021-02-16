setTimeout(function () {
    var scrollDiv = document.createElement("div");
    scrollDiv.className = "scrollbar-measure";
    document.body.appendChild(scrollDiv);
    var scrollbarWidth = scrollDiv.offsetWidth - scrollDiv.clientWidth;
    $('body').append(
        `<style>
            .disable-scroll{
                padding-right: ` + scrollbarWidth + `px; 
            }
            .disable-scroll .alert-box{
                padding-right: ` + scrollbarWidth + `px; 
            }
            .disable-scroll .cart-span{
                padding-right: ` + scrollbarWidth + `px; 
            }
        </style>`
    );
    document.body.removeChild(scrollDiv);
}, 500)