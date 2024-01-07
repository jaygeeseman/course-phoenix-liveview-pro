let Clipboard = {
    initialInnerHTML: "",
    content: "",
    mounted() {
        this.updated();

        this.el.addEventListener("click", () => {
            navigator.clipboard.writeText(content);

            this.el.innerHTML = "Copied!";

            setTimeout(() => {
                this.el.innerHTML = initialInnerHTML;
            }, 2000);
        });

        console.log("hook created", this.el.dataset);
    },
    updated() {
        initialInnerHTML = this.el.innerHTML;
        content = this.el.dataset.content;
    }
}

export default Clipboard;
