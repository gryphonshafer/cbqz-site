'use strict';

( () => {
    const size_iframe = () => {
        const iframe = document.querySelector('iframe');
        if (iframe) {
            iframe.addEventListener( 'load', () => {
                iframe.style.height = '0px';
                iframe.style.height = (
                    iframe.contentWindow.document.body.scrollHeight + (
                        ( navigator.userAgent.includes('Firefox') ) ? 40 : 140
                    )
                ) + 'px';
            } );
        }
    };

    window.addEventListener( 'DOMContentLoaded', size_iframe );
    window.addEventListener( 'resize', size_iframe );
} )();
