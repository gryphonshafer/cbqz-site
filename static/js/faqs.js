window.addEventListener( 'DOMContentLoaded', () => {
    const headings = document.querySelectorAll('h2, h3');

    headings.forEach( heading => {
        if ( heading.tagName === 'H3' ) {
            const details = document.createElement('details');
            const summary = document.createElement('summary');

            summary.innerHTML = heading.innerHTML;

            const content = [];
            let nextSibling = heading.nextSibling;

            while (
                nextSibling &&
                nextSibling.tagName !== 'H2' &&
                nextSibling.tagName !== 'H3' &&
                nextSibling.tagName !== 'DIV'
            ) {
                content.push(nextSibling);
                nextSibling = nextSibling.nextSibling;
            }

            heading.parentNode.replaceChild( details, heading );
            details.appendChild(summary);
            content.forEach( node => details.appendChild(node) );
        }

    } );
} );
