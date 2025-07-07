window.addEventListener( 'DOMContentLoaded', () => {
    const quizzer_displays = window.document.querySelectorAll('.quizzer_display');
    window.document.querySelectorAll('input[name="quizzer_display"]').forEach( ( input, index ) => {
        input.checked = ! index;
        if ( ! index) window.document.querySelector( '#quizzers_' + input.value ).classList.remove('hidden');
        input.onchange = () => {
            quizzer_displays.forEach( display => display.classList.add('hidden') );
            window.document.querySelector( '#quizzers_' + input.value ).classList.remove('hidden');
        };
    } );
} );
